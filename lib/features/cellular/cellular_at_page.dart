// 蜂窝 · AT 调试（W6.14；层级/命令面与网页端 qmodem「Advance Modem Settings →
// AT Debug」对齐）：端口选择（含无效/非本模组标注）+ 预置命令 + 输入 + 累积输出。
//
// 纪律（IA v2 定案 D4′）：**命令面不缩水**——网页端能发的这里都能发；风险由用户
// 自担，界面只做风险警告；发送前二次确认；app-api 侧逐条注册 + logd 审计。
// 语言：请求时带 `lang`（App 界面语言）——上游受控 fork 支持该可选参数。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularAtPage extends ConsumerStatefulWidget {
  const CellularAtPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularAtPage> createState() => _CellularAtPageState();
}

class _AtPort {
  const _AtPort({required this.value, required this.own, required this.valid});

  final String value;

  /// 是否属于当前模组（来自 `ports`）。
  final bool own;

  /// 是否在 `valid_ports` 白名单内；无白名单时默认 own 即可用。
  final bool valid;

  bool get usable => own && valid;
}

class _CellularAtPageState extends ConsumerState<CellularAtPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  List<_AtPort> _ports = const [];
  String _port = '';
  List<(String, String)> _cmds = const [];
  final List<String> _lines = [];
  bool _sending = false;
  bool _loaded = false;
  bool _cfgLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFast();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _lang {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'zh' ? 'zh' : 'en';
  }

  _AtPort? get _selectedPort {
    for (final p in _ports) {
      if (p.value == _port) return p;
    }
    return null;
  }

  /// 先走轻量端口列表（tty_ports + 快照 at_port），不被 `get_at_cfg` 的端口探测阻塞；
  /// 预置命令与 valid/other 标注随后后台补齐（与网页端同一份 `at_cfg` 数据）。
  Future<void> _loadFast() async {
    final modem = ref
        .read(snapshotProvider)
        .data
        ?.cellular
        ?.modems
        .where((x) => x.id == widget.section)
        .firstOrNull;
    final atPort = modem?.atPort ?? '';
    final ports = <String>{if (atPort.isNotEmpty) atPort};
    final client = ref.read(qmodemClientProvider);
    if (client != null) {
      final r = await client.call('qmodem.tty_ports');
      if (r.ok) {
        for (final p in (r.map['ports'] as List? ?? const [])) {
          if (p is String && p.isNotEmpty) {
            ports.add(p);
          } else if (p is Map) {
            final id = p['id'];
            if (id is String && id.isNotEmpty) ports.add(id);
          }
        }
      }
    }
    if (!mounted) return;
    final list = ports.toList(growable: false);
    setState(() {
      _loaded = true;
      _ports = [
        for (final p in list) _AtPort(value: p, own: true, valid: true),
      ];
      _port = atPort.isNotEmpty ? atPort : (list.isEmpty ? '' : list.first);
    });
    _loadCfg();
  }

  Future<void> _loadCfg() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    setState(() => _cfgLoading = true);
    final r = await client.call(
      'qmodem.at_cfg',
      section: widget.section,
      args: {'lang': _lang},
    );
    final own = <String>[];
    final other = <String>[];
    final valid = <String>[];
    var using = '';
    final cmds = <(String, String)>[];
    if (r.ok) {
      // 上游 `get_at_cfg` 返回 `{at_cfg:{ports,other_ttys,valid_ports,using_port,cmds}}`；
      // 兼容旧/新形态（app-api 某些版本可能已解包为顶层）。
      final raw = r.map;
      final m = raw['at_cfg'] is Map<String, dynamic>
          ? raw['at_cfg'] as Map<String, dynamic>
          : raw;
      for (final p in (m['ports'] as List? ?? const [])) {
        if (p is String && p.isNotEmpty) own.add(p);
      }
      for (final p in (m['other_ttys'] as List? ?? const [])) {
        if (p is String && p.isNotEmpty) other.add(p);
      }
      for (final p in (m['valid_ports'] as List? ?? const [])) {
        if (p is String && p.isNotEmpty) valid.add(p);
      }
      using = (m['using_port'] as String?) ?? '';
      for (final c in (m['cmds'] as List? ?? const [])) {
        if (c is Map) {
          final name = c['name'] as String? ?? '';
          final value = c['value'] as String? ?? '';
          if (name.isNotEmpty && value.isNotEmpty) cmds.add((name, value));
        }
      }
    }
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _cfgLoading = false);
      return;
    }
    final merged = <String>[...own, ...other];
    final ports = [
      for (final p in merged)
        _AtPort(
          value: p,
          own: own.contains(p),
          valid: valid.isEmpty ? own.contains(p) : valid.contains(p),
        ),
    ];
    var selected = ports
        .where((p) => p.value == _port && p.usable)
        .firstOrNull
        ?.value;
    selected ??= ports
        .where((p) => p.value == using && p.usable)
        .firstOrNull
        ?.value;
    selected ??= ports.where((p) => p.usable).firstOrNull?.value;
    selected ??= _port;
    setState(() {
      _ports = ports;
      _port = selected!;
      _cmds = cmds;
      _cfgLoading = false;
    });
  }

  void _append(String text) {
    if (text.isEmpty) return;
    setState(() => _lines.add(text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearOutput() {
    setState(() => _lines.clear());
  }

  String _portLabel(AppL10n l10n, _AtPort p) {
    if (!p.own) return l10n.cellularAtPortOther(p.value);
    if (!p.valid) return l10n.cellularAtPortInvalid(p.value);
    return p.value;
  }

  Future<void> _pickPort() async {
    final l10n = AppL10n.of(context);
    final picked = await showQzSheet<String>(
      context,
      builder: (ctx) {
        final t = QuartzTokens.of(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cellularAtSelectPort,
              textAlign: TextAlign.center,
              style: QuartzType.heroTitle.copyWith(color: t.text),
            ),
            const SizedBox(height: 8),
            for (final (i, p) in _ports.indexed)
              QzListRow(
                first: i == 0,
                title: _portLabel(l10n, p),
                showChevron: false,
                trailing: p.value == _port
                    ? QzIcon(QzIcons.check, size: 18, color: t.accent)
                    : null,
                onTap: p.usable ? () => Navigator.of(ctx).pop(p.value) : null,
              ),
            const SizedBox(height: 8),
            QzButton(
              label: l10n.cancel,
              kind: QzButtonKind.plain,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
    if (picked != null && mounted) setState(() => _port = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final selected = _selectedPort;
    final canSend =
        selected?.usable == true && _ctrl.text.trim().isNotEmpty && !_sending;
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.cellularEntryAt,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          QzHeaderAction(
            label: l10n.cellularAtClearOutput,
            onTap: _lines.isEmpty ? null : _clearOutput,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InfoBanner(
            title: l10n.cellularAtWarningTitle,
            body: l10n.cellularAtWarningBody,
          ),
          if (!_loaded)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: QzSpinner(size: 22)),
            )
          else ...[
            QuartzCard(
              title: l10n.cellularAtSend,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_ports.isEmpty)
                    Text(
                      l10n.cellularAtNoPorts,
                      style: QuartzType.caption.copyWith(color: t.faint),
                    )
                  else
                    QzSelectRow(
                      label: l10n.cellularAtPort,
                      value: selected == null
                          ? null
                          : _portLabel(l10n, selected),
                      onTap: _ports.length <= 1 ? null : _pickPort,
                      first: true,
                    ),
                  if (selected != null && !selected.usable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.cellularAtInvalidPortWarning,
                        style: QuartzType.caption.copyWith(color: t.warn),
                      ),
                    ),
                  const SizedBox(height: 10),
                  QzField(
                    controller: _ctrl,
                    hint: 'AT+QCAINFO',
                    monospace: true,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _send(),
                    suffix: QzInlineIconButton(
                      icon: QzIcons.close,
                      tooltip: l10n.clearAction,
                      onTap: _ctrl.text.isEmpty
                          ? null
                          : () => setState(_ctrl.clear),
                    ),
                  ),
                  const SizedBox(height: 10),
                  QzButton(
                    label: _sending ? l10n.loading : l10n.cellularAtSend,
                    expand: true,
                    onPressed: canSend ? _send : null,
                  ),
                ],
              ),
            ),
            if (_cmds.isNotEmpty)
              _presetCard(l10n)
            else if (_cfgLoading)
              QuartzCard(
                title: l10n.cellularAtPresets,
                child: Row(
                  children: [
                    const QzSpinner(size: 16, stroke: 2),
                    const SizedBox(width: 8),
                    Text(
                      l10n.loading,
                      style: QuartzType.caption.copyWith(color: t.faint),
                    ),
                  ],
                ),
              ),
            QuartzCard(
              title: l10n.cellularAtOutput,
              trailing: QzHeaderAction(
                label: l10n.clearAction,
                onTap: _lines.isEmpty ? null : _clearOutput,
              ),
              child: Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.well.withValues(alpha: t.panelAlpha),
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(QuartzRadii.sm),
                ),
                child: _lines.isEmpty
                    ? Text(
                        l10n.cellularAtOutputEmpty,
                        style: QuartzType.caption.copyWith(color: t.faint),
                      )
                    : SingleChildScrollView(
                        controller: _scroll,
                        child: SelectableText(
                          _lines.join('\n\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 预置命令（点击填入输入框；名称与顺序即上游 `at_commands_{zh,en}.json`）。
  Widget _presetCard(AppL10n l10n) {
    final t = QuartzTokens.of(context);
    return QuartzCard(
      title: l10n.cellularAtPresets,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final (name, value) in _cmds)
            QzPressable(
              highlight: true,
              onTap: () => setState(() => _ctrl.text = value),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: t.borderStrong),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 发送：经 `qmodem.send_at` 转发条目（app-api 侧字符集/端口白名单校验 + logd 审计）；
  /// 响应取自上游返回的 `at_cfg.res`（与网页端同一字段），追加到累积输出。
  Future<void> _send() async {
    final l10n = AppL10n.of(context);
    final at = _ctrl.text.trim();
    if (at.isEmpty) return;
    final selected = _selectedPort;
    if (selected == null || !selected.usable) return;
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.cellularAtConfirmTitle(at),
      body: l10n.cellularAtWarningBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    setState(() => _sending = true);
    final portLabel = _portLabel(l10n, selected);
    _append('> $at  [$portLabel]');
    final r = await client.call(
      'qmodem.send_at',
      section: widget.section,
      args: {'params': '{"at":${_jsonStr(at)},"port":"${selected.value}"}'},
    );
    if (!mounted) return;
    final atCfg = r.map['at_cfg'];
    final res = atCfg is Map ? (atCfg['res'] as String? ?? '') : '';
    setState(() => _sending = false);
    _append(
      r.ok
          ? (res.isNotEmpty ? res : l10n.actionDone)
          : '! ${l10n.actionFailed(r.message)}',
    );
  }

  static String _jsonStr(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}
