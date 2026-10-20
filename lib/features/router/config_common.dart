// 路由器 tab · 配置面通用件（W6.10/W6.11）。
//
// 机制：
// - [ConfigField]：页面侧的字段描述（标签/类型/枚举/危险标记）；**类型与枚举的
//   最终裁决在路由器注册表**（app-api `internal/uciconf/registry.go`），本层只
//   负责渲染与收集改动，不另立限制。
// - [ConfigDraft]：原始值 vs 当前值，产出 dirty set；敏感字段的 `__masked__`
//   占位符**永不回写**（未修改则不发该字段）。
// - [applyConfigEdits]：逐字段 write（暂存）→ apply(rollback,90s) → 倒计时确认
//   条（保留 / 立即回滚）。**立即回滚走 `config.rollback`**，不是 revert。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../api/envelope.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';

enum ConfigFieldKind { text, integer, boolean, choice, list, secret }

class ConfigChoice {
  const ConfigChoice(this.value, this.label);

  final String value;
  final String label;
}

class ConfigField {
  const ConfigField(
    this.option,
    this.label, {
    this.kind = ConfigFieldKind.text,
    this.choices = const [],
    this.min,
    this.max,
    this.hint,
    this.sensitive = false,
    this.dangerous = false,
    this.visibleWhen,
  });

  /// UCI 选项名。
  final String option;

  /// 本地化标签。
  final String label;
  final ConfigFieldKind kind;
  final List<ConfigChoice> choices;
  final int? min;
  final int? max;
  final String? hint;

  /// 读面返回 `__masked__`；未修改时不得回写。
  final bool sensitive;

  /// 改动该字段时额外弹危险确认（如 LAN IP / 无线密码）。
  final bool dangerous;

  /// 协议/模式驱动的可见性（如静态 IP 字段仅在 proto=static 时显示）。
  final bool Function(Map<String, dynamic> values)? visibleWhen;
}

class ConfigEdit {
  const ConfigEdit(this.config, this.section, this.option, this.value);

  final String config;
  final String section;
  final String option;
  final dynamic value;
}

bool configBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

int? configInt(dynamic v) {
  if (v == null || v == '') return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

/// 表单/回显的统一文本（列表空格连接；null → 空串）。
String configValueText(dynamic v) {
  if (v == null) return '';
  if (v is List) return v.map((e) => '$e').join(' ');
  return '$v';
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameValue(dynamic a, dynamic b) {
  if (a is List && b is List) {
    return _listEq(a.map((e) => '$e').toList(), b.map((e) => '$e').toList());
  }
  return a == b;
}

/// 一节的编辑草稿（纯逻辑，单测覆盖）。
class ConfigDraft {
  ConfigDraft({
    required this.config,
    required this.section,
    required this.fields,
    required Map<String, dynamic> initial,
  }) : _initial = Map.of(initial),
       _current = Map.of(initial);

  final String config;
  final String section;
  final List<ConfigField> fields;
  Map<String, dynamic> _initial;
  Map<String, dynamic> _current;

  Map<String, dynamic> get current => Map.unmodifiable(_current);
  Map<String, dynamic> get initial => Map.unmodifiable(_initial);
  bool get hasChanges => visibleFields.any(isDirty);

  List<ConfigField> get visibleFields =>
      fields.where((f) => f.visibleWhen?.call(_current) ?? true).toList();

  dynamic rawValue(ConfigField f) => _current[f.option];

  void reset(Map<String, dynamic> initial) {
    _initial = Map.of(initial);
    _current = Map.of(initial);
  }

  void set(ConfigField f, dynamic value) {
    if (value == null) {
      _current.remove(f.option);
    } else {
      _current[f.option] = value;
    }
  }

  /// 文本输入：敏感字段留空 = 保持原值（`__masked__` 或未设置）。
  void setText(ConfigField f, String text) {
    if (f.sensitive) {
      if (text.isEmpty) {
        final orig = _initial[f.option];
        if (orig != null) {
          _current[f.option] = orig;
        } else {
          _current.remove(f.option);
        }
        return;
      }
      _current[f.option] = text;
      return;
    }
    switch (f.kind) {
      case ConfigFieldKind.integer:
        final n = int.tryParse(text.trim());
        if (n == null) {
          _current.remove(f.option);
        } else {
          _current[f.option] = n;
        }
      case ConfigFieldKind.list:
        final t = text.trim();
        _current[f.option] = t.isEmpty ? <String>[] : t.split(RegExp(r'\s+'));
      default:
        _current[f.option] = text;
    }
  }

  dynamic _normalized(ConfigField f, dynamic v) {
    switch (f.kind) {
      case ConfigFieldKind.boolean:
        return configBool(v);
      case ConfigFieldKind.integer:
        return configInt(v);
      case ConfigFieldKind.list:
        if (v is List) return v.map((e) => '$e').toList();
        final s = '${v ?? ''}'.trim();
        return s.isEmpty ? <String>[] : s.split(RegExp(r'\s+'));
      case ConfigFieldKind.choice:
        return v == null ? null : '$v';
      case ConfigFieldKind.text:
      case ConfigFieldKind.secret:
        return v == null ? '' : '$v';
    }
  }

  bool isDirty(ConfigField f) {
    final cur = _normalized(f, _current[f.option]);
    final old = _normalized(f, _initial[f.option]);
    // 敏感字段：原值就是掩码时，未被用户改写（仍是掩码）不算改动。
    if (f.sensitive && old == '__masked__' && rawValue(f) == '__masked__') {
      return false;
    }
    // 整数输入被清空 = 无效输入（不写），不当作待保存改动。
    if (f.kind == ConfigFieldKind.integer && cur == null) return false;
    return !_sameValue(cur, old);
  }

  /// 待写字段（仅可见字段；空值不写）。
  List<ConfigEdit> edits() {
    final out = <ConfigEdit>[];
    for (final f in visibleFields) {
      if (!isDirty(f)) continue;
      final v = _normalized(f, _current[f.option]);
      if (v == null) continue;
      out.add(ConfigEdit(config, section, f.option, v));
    }
    return out;
  }
}

/// 错误码 → 本地化文案（配置面专用）。
String configErrorText(AppL10n l10n, ApiError? err) {
  final detail = apiErrorText(err);
  final lower = detail.toLowerCase();
  return switch (err?.code) {
    'data_unavailable' => l10n.configSessionUnavailable,
    'forbidden_action' => l10n.configForbidden,
    'bad_request' => l10n.configBadValue(detail),
    'action_failed' || 'unknown' =>
      lower.contains('permission_denied') ||
              lower.contains('permission denied') ||
              lower.contains('rollback')
          ? l10n.configWebPending
          : l10n.configApplyFailed(detail),
    'access_denied' => l10n.configWebPending,
    _ => l10n.actionFailed(detail),
  };
}

void showConfigSnack(BuildContext context, String text) {
  showQzToast(context, text);
}

/// 单个字段控件（布尔开关 / 枚举选择 / 文本框）。
class ConfigFieldTile extends StatelessWidget {
  const ConfigFieldTile({
    super.key,
    required this.field,
    required this.value,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final ConfigField field;
  final dynamic value;
  final TextEditingController? controller;
  final ValueChanged<dynamic> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    switch (field.kind) {
      case ConfigFieldKind.boolean:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: QuartzType.body.copyWith(color: t.text),
                    ),
                    if (field.hint != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        field.hint!,
                        style: QuartzType.caption.copyWith(color: t.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              QzToggle(
                value: configBool(value),
                semanticLabel: field.label,
                onChanged: enabled ? (v) => onChanged(v) : null,
              ),
            ],
          ),
        );
      case ConfigFieldKind.choice:
        final current = value == null ? '' : '$value';
        String? label;
        for (final c in field.choices) {
          if (c.value == current) {
            label = c.label;
            break;
          }
        }
        return QzSelectRow(
          label: field.label,
          value: label ?? (current.isEmpty ? l10n.configUnset : current),
          enabled: enabled,
          onTap: () => _choose(context),
        );
      case ConfigFieldKind.text:
      case ConfigFieldKind.integer:
      case ConfigFieldKind.list:
      case ConfigFieldKind.secret:
        final masked = field.sensitive && value == '__masked__';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QzField(
                controller: controller,
                label: field.label,
                hint: masked
                    ? l10n.configSensitiveHint
                    : (field.hint ?? l10n.configUnset),
                enabled: enabled,
                obscure: field.sensitive,
                keyboardType: field.kind == ConfigFieldKind.integer
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: field.kind == ConfigFieldKind.integer
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                onChanged: (v) => onChanged(v),
              ),
              if (!masked && field.hint != null) ...[
                const SizedBox(height: 3),
                Text(
                  field.hint!,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ],
          ),
        );
    }
  }

  Future<void> _choose(BuildContext context) async {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final picked = await showQzSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.label,
            textAlign: TextAlign.center,
            style: QuartzType.heroTitle.copyWith(color: t.text),
          ),
          const SizedBox(height: 8),
          for (final (i, c) in field.choices.indexed)
            QzListRow(
              first: i == 0,
              title: c.label,
              showChevron: false,
              trailing: c.value == '$value'
                  ? QzIcon(QzIcons.check, size: 18, color: t.accent)
                  : null,
              onTap: () => Navigator.of(ctx).pop(c.value),
            ),
          const SizedBox(height: 8),
          QzButton(
            label: l10n.cancel,
            kind: QzButtonKind.plain,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

class ConfigGroupEditor extends ConsumerStatefulWidget {
  const ConfigGroupEditor({
    super.key,
    required this.config,
    required this.section,
    required this.title,
    required this.fields,
    required this.initial,
    this.subtitle,
    this.danger = false,
    this.dangerBody,
    this.onSaved,
  });

  final String config;
  final String section;
  final String title;
  final List<ConfigField> fields;
  final Map<String, dynamic> initial;
  final String? subtitle;
  final bool danger;
  final String? dangerBody;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ConfigGroupEditor> createState() => _ConfigGroupEditorState();
}

class _ConfigGroupEditorState extends ConsumerState<ConfigGroupEditor> {
  late ConfigDraft _draft;
  final Map<String, TextEditingController> _controllers = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant ConfigGroupEditor old) {
    super.didUpdateWidget(old);
    final changed =
        old.section != widget.section ||
        old.config != widget.config ||
        !_sameMap(old.initial, widget.initial);
    if (changed && !_draft.hasChanges) _reset();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    _draft = ConfigDraft(
      config: widget.config,
      section: widget.section,
      fields: widget.fields,
      initial: widget.initial,
    );
    final stale = _controllers.keys.toList();
    for (final f in widget.fields) {
      if (!_isTextual(f.kind)) continue;
      final raw = widget.initial[f.option];
      final masked = f.sensitive && raw == '__masked__';
      final ctrl = TextEditingController(
        text: masked ? '' : configValueText(raw),
      );
      _controllers[f.option]?.dispose();
      _controllers[f.option] = ctrl;
      stale.remove(f.option);
    }
    for (final k in stale) {
      _controllers.remove(k)?.dispose();
    }
  }

  bool _isTextual(ConfigFieldKind k) =>
      k == ConfigFieldKind.text ||
      k == ConfigFieldKind.integer ||
      k == ConfigFieldKind.list ||
      k == ConfigFieldKind.secret;

  bool get _dangerousChange =>
      _draft.visibleFields.any((f) => f.dangerous && _draft.isDirty(f));

  Future<void> _save() async {
    final edits = _draft.edits();
    if (edits.isEmpty) {
      showConfigSnack(context, AppL10n.of(context).configNoChanges);
      return;
    }
    setState(() => _busy = true);
    final outcome = await applyConfigEdits(
      context,
      ref,
      edits: edits,
      danger: widget.danger || _dangerousChange,
      dangerBody: widget.dangerBody,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (outcome != null) _reset();
    });
    if (outcome != null) widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final fields = _draft.visibleFields;
    return QuartzCard(
      title: widget.title,
      trailing: _draft.hasChanges
          ? QzChip(l10n.configDirtyChip, kind: QzChipKind.warn)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: QuartzType.caption.copyWith(color: t.muted),
            ),
            const SizedBox(height: 6),
          ],
          for (final f in fields)
            ConfigFieldTile(
              field: f,
              value: _draft.rawValue(f),
              controller: _controllers[f.option],
              enabled: !_busy,
              onChanged: (v) {
                if (_isTextual(f.kind) && v is String) {
                  _draft.setText(f, v);
                } else {
                  _draft.set(f, v);
                }
                setState(() {});
              },
            ),
          const SizedBox(height: 10),
          QzButton(
            label: _busy ? l10n.configSaving : l10n.save,
            expand: true,
            onPressed: _busy || !_draft.hasChanges ? null : _save,
          ),
        ],
      ),
    );
  }
}

bool _sameMap(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!_sameValue(e.value, b[e.key])) return false;
  }
  return true;
}

enum ApplyOutcome { confirmed, rolledBack, timedOut }

/// add/delete → apply → 倒计时确认（W6.11 静态租约等结构变更）。
/// 返回 null 表示危险确认取消或变更/应用失败。
Future<ApplyOutcome?> applyConfigMutation(
  BuildContext context,
  WidgetRef ref, {
  required String config,
  required Future<ApiResult> Function(ConfigClient client) mutate,
  bool danger = false,
  String? dangerBody,
}) async {
  final l10n = AppL10n.of(context);
  final client = ref.read(configClientProvider);
  if (client == null) return null;
  if (danger) {
    final ok = await showConfirmSheet(
      context,
      title: l10n.configDangerTitle,
      body: dangerBody ?? l10n.configDangerBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return null;
  }
  final r = await mutate(client);
  if (!r.ok) {
    await client.revert(config);
    if (context.mounted) {
      showConfigSnack(context, configErrorText(l10n, r.error));
    }
    return null;
  }
  final applied = await client.apply(rollback: true, timeout: 90);
  if (!applied.ok) {
    await client.revert(config);
    if (context.mounted) {
      showConfigSnack(context, configErrorText(l10n, applied.error));
    }
    return null;
  }
  if (!context.mounted) return null;
  final outcome = await showApplyGuard(context, client, timeout: 90);
  if (!context.mounted) return outcome;
  switch (outcome) {
    case ApplyOutcome.confirmed:
      showConfigSnack(context, l10n.configSaved);
    case ApplyOutcome.rolledBack:
      showConfigSnack(context, l10n.configRollbackDone);
    case ApplyOutcome.timedOut:
      showConfigSnack(context, l10n.configAutoRolledBack);
  }
  return outcome;
}

/// 写 → apply → 倒计时确认；返回 null 表示用户在危险确认处取消（尚未写）。
Future<ApplyOutcome?> applyConfigEdits(
  BuildContext context,
  WidgetRef ref, {
  required List<ConfigEdit> edits,
  bool danger = false,
  String? dangerBody,
}) async {
  final l10n = AppL10n.of(context);
  final client = ref.read(configClientProvider);
  if (client == null) return null;

  if (danger) {
    final ok = await showConfirmSheet(
      context,
      title: l10n.configDangerTitle,
      body: dangerBody ?? l10n.configDangerBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return null;
  }

  final configs = edits.map((e) => e.config).toSet();
  for (final e in edits) {
    final r = await client.write(e.config, e.section, e.option, e.value);
    if (!r.ok) {
      for (final c in configs) {
        await client.revert(c);
      }
      if (context.mounted) {
        showConfigSnack(context, configErrorText(l10n, r.error));
      }
      return null;
    }
  }

  final applied = await client.apply(rollback: true, timeout: 90);
  if (!applied.ok) {
    for (final c in configs) {
      await client.revert(c);
    }
    if (context.mounted) {
      showConfigSnack(context, configErrorText(l10n, applied.error));
    }
    return null;
  }
  if (!context.mounted) return null;

  final outcome = await showApplyGuard(context, client, timeout: 90);
  if (!context.mounted) return outcome;
  switch (outcome) {
    case ApplyOutcome.confirmed:
      showConfigSnack(context, l10n.configSaved);
    case ApplyOutcome.rolledBack:
      showConfigSnack(context, l10n.configRollbackDone);
    case ApplyOutcome.timedOut:
      showConfigSnack(context, l10n.configAutoRolledBack);
  }
  return outcome;
}

/// apply 之后的常驻确认条：90s 倒计时（不确认 = 路由器自动回滚）。
Future<ApplyOutcome> showApplyGuard(
  BuildContext context,
  ConfigClient client, {
  int timeout = 90,
}) async {
  final r = await showQzSheet<ApplyOutcome>(
    context,
    dismissible: false,
    builder: (_) => _ApplyGuardSheet(client: client, timeout: timeout),
  );
  return r ?? ApplyOutcome.timedOut;
}

class _ApplyGuardSheet extends StatefulWidget {
  const _ApplyGuardSheet({required this.client, required this.timeout});

  final ConfigClient client;
  final int timeout;

  @override
  State<_ApplyGuardSheet> createState() => _ApplyGuardSheetState();
}

class _ApplyGuardSheetState extends State<_ApplyGuardSheet> {
  late int _left = widget.timeout;
  late final Timer _timer;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        Navigator.of(context).pop(ApplyOutcome.timedOut);
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final r = await widget.client.confirm();
    if (!mounted) return;
    if (r.ok) {
      _timer.cancel();
      Navigator.of(context).pop(ApplyOutcome.confirmed);
    } else {
      setState(() {
        _busy = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
    }
  }

  Future<void> _rollback() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final r = await widget.client.rollback();
    if (!mounted) return;
    if (r.ok) {
      _timer.cancel();
      Navigator.of(context).pop(ApplyOutcome.rolledBack);
    } else {
      setState(() {
        _busy = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.configApplyTitle,
            textAlign: TextAlign.center,
            style: QuartzType.heroTitle.copyWith(color: t.text),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.configApplyCountdown(_left),
            textAlign: TextAlign.center,
            style: QuartzType.metric.copyWith(
              color: _left <= 15 ? t.err : t.accent,
            ),
          ),
          const SizedBox(height: 8),
          QzBar(
            pct: _left / widget.timeout,
            height: 4,
            color: _left <= 15 ? t.err : t.warn,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.configApplyBody,
            textAlign: TextAlign.center,
            style: QuartzType.sub.copyWith(color: t.muted, height: 1.55),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: QuartzType.caption.copyWith(color: t.err),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QzButton(
                  label: l10n.configRollbackNow,
                  kind: QzButtonKind.danger,
                  expand: true,
                  onPressed: _busy ? null : _rollback,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QzButton(
                  label: l10n.configKeepChanges,
                  expand: true,
                  onPressed: _busy ? null : _confirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 通用 section 编辑/新增底部表单（防火墙 / 挂载 / LED 共用）。
/// section == null 时走 config.add（按 addType），否则走 config.write 的 dirty set。
class ConfigSectionSheet extends ConsumerStatefulWidget {
  const ConfigSectionSheet({
    super.key,
    required this.title,
    required this.config,
    required this.section,
    required this.addType,
    required this.fields,
    required this.initial,
    this.danger = false,
    this.dangerBody,
  });

  final String title;
  final String config;
  final String? section; // null = 新增
  final String addType;
  final List<ConfigField> fields;
  final Map<String, dynamic> initial;
  final bool danger;
  final String? dangerBody;

  @override
  ConsumerState<ConfigSectionSheet> createState() => _ConfigSectionSheetState();
}

class _ConfigSectionSheetState extends ConsumerState<ConfigSectionSheet> {
  late ConfigDraft _draft;
  final Map<String, TextEditingController> _controllers = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _draft = ConfigDraft(
      config: widget.config,
      section: widget.section ?? '',
      fields: widget.fields,
      initial: widget.initial,
    );
    for (final f in widget.fields) {
      if (!_textual(f.kind)) continue;
      _controllers[f.option] = TextEditingController(
        text: configValueText(widget.initial[f.option]),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _textual(ConfigFieldKind k) =>
      k == ConfigFieldKind.text ||
      k == ConfigFieldKind.integer ||
      k == ConfigFieldKind.list ||
      k == ConfigFieldKind.secret;

  bool get _dangerous =>
      widget.danger ||
      _draft.visibleFields.any((f) => f.dangerous && _draft.isDirty(f));

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    if (_busy) return;
    setState(() => _busy = true);
    ApplyOutcome? outcome;
    if (widget.section == null) {
      final values = <String, dynamic>{};
      for (final f in _draft.visibleFields) {
        final v = _draft.rawValue(f);
        if (v == null) continue;
        if (v is String && v.trim().isEmpty) continue;
        if (v is List && v.isEmpty) continue;
        values[f.option] = v;
      }
      if (values.isEmpty) {
        setState(() => _busy = false);
        showConfigSnack(context, l10n.firewallAtLeastOne);
        return;
      }
      outcome = await applyConfigMutation(
        context,
        ref,
        config: widget.config,
        danger: _dangerous,
        dangerBody: widget.dangerBody,
        mutate: (client) => client.add(widget.config, widget.addType, values),
      );
    } else {
      final edits = _draft.edits();
      if (edits.isEmpty) {
        setState(() => _busy = false);
        showConfigSnack(context, l10n.configNoChanges);
        return;
      }
      outcome = await applyConfigEdits(
        context,
        ref,
        edits: edits,
        danger: _dangerous,
        dangerBody: widget.dangerBody,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    return ColoredBox(
      color: t.raised,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: QuartzType.heroTitle.copyWith(color: t.text),
                  ),
                ),
                QzIconButton(
                  icon: QzIcons.close,
                  tooltip: l10n.cancel,
                  onTap: _busy ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          QzDivider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              children: [
                for (final f in _draft.visibleFields)
                  ConfigFieldTile(
                    field: f,
                    value: _draft.rawValue(f),
                    controller: _controllers[f.option],
                    enabled: !_busy,
                    onChanged: (v) {
                      if (_textual(f.kind) && v is String) {
                        _draft.setText(f, v);
                      } else {
                        _draft.set(f, v);
                      }
                      setState(() {});
                    },
                  ),
                const SizedBox(height: 6),
                Text(
                  l10n.configSheetHint,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: QzButton(
                label: _busy ? l10n.configSaving : l10n.save,
                expand: true,
                onPressed: _busy ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
