// 蜂窝 · AT 调试（W6.14）：预置命令（**与网页端同源** `get_at_cfg.cmds`）+ 端口选择
// + 发送 + 等宽响应区。
//
// 纪律（IA v2 定案 D4′）：**命令面不缩水**——网页端能发的这里都能发；风险由用户
// 自担，界面只做风险警告；发送前二次确认；app-api 侧逐条注册 + logd 审计。
// 语言：请求时带 `lang`（App 界面语言）——上游受控 fork 支持该可选参数。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularAtPage extends ConsumerStatefulWidget {
  const CellularAtPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularAtPage> createState() => _CellularAtPageState();
}

class _CellularAtPageState extends ConsumerState<CellularAtPage> {
  final _ctrl = TextEditingController();

  List<String> _ports = const [];
  String _port = '';
  List<(String, String)> _cmds = const [];
  String _response = '';
  bool _sending = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _lang {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'zh' ? 'zh' : 'en';
  }

  /// 取 AT 端口 + 预置命令（与网页端同一份数据；带 App 语言）。
  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final r = await client.call('qmodem.at_cfg', section: widget.section, args: {'lang': _lang});
    final ports = <String>[];
    var using = '';
    final cmds = <(String, String)>[];
    if (r.ok) {
      final m = r.map;
      for (final p in (m['ports'] as List? ?? const [])) {
        if (p is String && p.isNotEmpty) ports.add(p);
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
    setState(() {
      _loaded = true;
      _ports = ports;
      _port = ports.contains(using) ? using : (ports.isEmpty ? '' : ports.first);
      _cmds = cmds;
      if (!r.ok) _response = r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellularEntryAt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _response = ''),
            child: Text(l10n.clearAction),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InfoBanner(title: l10n.cellularAtWarningTitle, body: l10n.cellularAtWarningBody),
          if (!_loaded)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else ...[
            QuartzCard(
              title: l10n.cellularAtSend,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_ports.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SegmentBar<String>(
                        values: _ports,
                        selected: _port.isEmpty ? _ports.first : _port,
                        labelOf: (p) => p,
                        onChanged: (p) => setState(() => _port = p),
                      ),
                    ),
                  TextField(
                    controller: _ctrl,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'AT+QCAINFO',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _sending ? null : _send,
                          child: Text(_sending ? l10n.loading : l10n.confirm),
                        ),
                      ),
                    ],
                  ),
                  if (_response.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _response,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_cmds.isNotEmpty) _presetCard(l10n),
          ],
        ],
      ),
    );
  }

  /// 预置命令（点击填入输入框；名称与顺序即上游 `at_commands_{zh,en}.json`）。
  Widget _presetCard(AppL10n l10n) {
    return QuartzCard(
      title: l10n.cellularAtPresets,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final (name, value) in _cmds)
            InkWell(
              onTap: () => setState(() => _ctrl.text = value),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  /// 发送：经 `qmodem.send_at` 转发条目（app-api 侧字符集/端口白名单校验 + logd 审计）；
  /// 响应取自上游返回的 `at_cfg.res`（与网页端同一字段）。
  Future<void> _send() async {
    final l10n = AppL10n.of(context);
    final at = _ctrl.text.trim();
    if (at.isEmpty) return;
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
    setState(() {
      _sending = true;
      _response = '';
    });
    final port = _port;
    final params = '{"at":${_jsonStr(at)}${port.isEmpty ? '' : ',"port":"$port"'}}';
    final r = await client.call('qmodem.send_at', section: widget.section, args: {'params': params});
    if (!mounted) return;
    final atCfg = r.map['at_cfg'];
    final res = atCfg is Map ? (atCfg['res'] as String? ?? '') : '';
    final cmd = atCfg is Map ? (atCfg['cmd'] as String? ?? at) : at;
    setState(() {
      _sending = false;
      _response = r.ok
          ? '$cmd\n${res.isNotEmpty ? res : l10n.actionDone}'
          : l10n.actionFailed(r.message);
    });
  }

  static String _jsonStr(String s) => '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}
