// 蜂窝 · 拨号日志（W6.12）：读条目 `qmodem.dial_log`（上游 tail -100 文本）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularLogPage extends ConsumerStatefulWidget {
  const CellularLogPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularLogPage> createState() => _CellularLogPageState();
}

class _CellularLogPageState extends ConsumerState<CellularLogPage> {
  String _log = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final r = await client.call('qmodem.dial_log', section: widget.section);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _log = r.ok ? ((r.map['log'] as String?) ?? '') : r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.cellularEntryLog,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          QzLegacyButton(
            kind: QzButtonKind.ghost,
            onPressed: _load,
            child: Text(l10n.refresh),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: QzSpinner(size: 22))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                InfoBanner(
                  title: l10n.cellularLogHintTitle,
                  body: l10n.cellularLogHintBody,
                ),
                QuartzCard(
                  title: l10n.cellularEntryLog,
                  child: SelectableText(
                    _log.trim().isEmpty ? l10n.cellularLogEmpty : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
