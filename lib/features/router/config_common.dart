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
  })  : _initial = Map.of(initial),
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    switch (field.kind) {
      case ConfigFieldKind.boolean:
        return SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(field.label, style: theme.textTheme.bodyMedium),
          subtitle: field.hint == null ? null : Text(field.hint!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          value: configBool(value),
          onChanged: enabled ? (v) => onChanged(v) : null,
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(QuartzRadii.sm),
            onTap: enabled ? () => _choose(context) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  Expanded(child: Text(field.label, style: theme.textTheme.bodyMedium)),
                  Text(
                    label ?? (current.isEmpty ? l10n.configUnset : current),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? QuartzColors.accent : muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 18, color: muted),
                ],
              ),
            ),
          ),
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
              Text(field.label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const SizedBox(height: 5),
              TextField(
                controller: controller,
                enabled: enabled,
                obscureText: field.sensitive,
                keyboardType: field.kind == ConfigFieldKind.integer ? TextInputType.number : TextInputType.text,
                inputFormatters: field.kind == ConfigFieldKind.integer
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: masked ? l10n.configSensitiveHint : (field.hint ?? l10n.configUnset),
                  hintStyle: TextStyle(color: muted, fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) => onChanged(v),
              ),
              if (!masked && field.hint != null) ...[
                const SizedBox(height: 3),
                Text(field.hint!, style: theme.textTheme.bodySmall?.copyWith(color: muted, fontSize: 11)),
              ],
            ],
          ),
        );
    }
  }

  Future<void> _choose(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? QuartzColors.darkRaised : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(field.label, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in field.choices)
                    ListTile(
                      dense: true,
                      title: Text(c.label),
                      trailing: c.value == '$value' ? const Icon(Icons.check, size: 18) : null,
                      onTap: () => Navigator.of(ctx).pop(c.value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

/// 一节的编辑卡片（加载后的值 → 修改 → 保存/应用）。
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
    final changed = old.section != widget.section ||
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
      final ctrl = TextEditingController(text: masked ? '' : configValueText(raw));
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
    final fields = _draft.visibleFields;
    return QuartzCard(
      title: widget.title,
      trailing: _draft.hasChanges
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: QuartzColors.warn.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(l10n.configDirtyChip,
                  style: const TextStyle(fontSize: 11, color: QuartzColors.warn, fontWeight: FontWeight.w600)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                  ),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy || !_draft.hasChanges ? null : _save,
              child: Text(_busy ? l10n.configSaving : l10n.save),
            ),
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
      if (context.mounted) showConfigSnack(context, configErrorText(l10n, r.error));
      return null;
    }
  }

  final applied = await client.apply(rollback: true, timeout: 90);
  if (!applied.ok) {
    for (final c in configs) {
      await client.revert(c);
    }
    if (context.mounted) showConfigSnack(context, configErrorText(l10n, applied.error));
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
Future<ApplyOutcome> showApplyGuard(BuildContext context, ConfigClient client, {int timeout = 90}) async {
  final r = await showModalBottomSheet<ApplyOutcome>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: false,
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? QuartzColors.darkRaised : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(l10n.configApplyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            l10n.configApplyCountdown(_left),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: _left <= 15 ? QuartzColors.err : QuartzColors.accent,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.configApplyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .6),
              height: 1.5,
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: QuartzColors.err)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuartzColors.err,
                    side: BorderSide(color: QuartzColors.err.withValues(alpha: .4)),
                  ),
                  onPressed: _busy ? null : _rollback,
                  child: Text(l10n.configRollbackNow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: Text(l10n.configKeepChanges),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
