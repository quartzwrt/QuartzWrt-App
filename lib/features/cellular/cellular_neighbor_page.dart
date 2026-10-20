// 蜂窝 · 邻区信息（对齐 qmodem 网页端「Advance Modem Settings → Neighbor Cell」）。
//
// App 只读：app-api 不开放 `set_neighborcell`（小区锁定会直接改驻网，归网页端）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularNeighborPage extends ConsumerStatefulWidget {
  const CellularNeighborPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularNeighborPage> createState() =>
      _CellularNeighborPageState();
}

class _CellularNeighborPageState extends ConsumerState<CellularNeighborPage> {
  bool _loaded = false;
  bool _busy = false;
  String _error = '';
  List<Map<String, dynamic>> _lte = const [];
  List<Map<String, dynamic>> _nr = const [];
  Map<String, dynamic> _lock = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    setState(() => _busy = true);
    final r = await client.call('qmodem.neighborcell', section: widget.section);
    if (!mounted) return;
    final raw = r.map['neighborcell'] is Map<String, dynamic>
        ? r.map['neighborcell'] as Map<String, dynamic>
        : r.map;
    List<Map<String, dynamic>> list(String key) =>
        (raw[key] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    setState(() {
      _loaded = true;
      _busy = false;
      _error = r.ok ? '' : r.message;
      _lte = list('LTE');
      _nr = list('NR');
      _lock = raw['lockcell_status'] is Map<String, dynamic>
          ? raw['lockcell_status'] as Map<String, dynamic>
          : const {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final empty = _lte.isEmpty && _nr.isEmpty;
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.cellularEntryNeighbor,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          QzIconButton(
            icon: QzIcons.refresh,
            tooltip: l10n.refresh,
            onTap: _busy ? null : _load,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: QzSpinner(size: 22))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  l10n.cellularNeighborReadonly,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
                const SizedBox(height: 8),
                if (_error.isNotEmpty)
                  InfoBanner(
                    title: l10n.actionFailed(_error),
                    body: l10n.cellularRetryHint,
                  ),
                if (empty)
                  QuartzCard(
                    title: l10n.cellularEntryNeighbor,
                    child: Text(
                      _error.isNotEmpty
                          ? l10n.actionFailed(_error)
                          : l10n.cellularNeighborEmpty,
                      style: QuartzType.caption.copyWith(color: t.faint),
                    ),
                  )
                else ...[
                  if (_lte.isNotEmpty)
                    _cellCard(l10n, l10n.cellularNeighborLte, _lte),
                  if (_nr.isNotEmpty)
                    _cellCard(l10n, l10n.cellularNeighborNr, _nr),
                ],
                if (_lock.isNotEmpty)
                  QuartzCard(
                    title: l10n.cellularNeighborLock,
                    child: Column(
                      children: [
                        for (final (i, e) in _lock.entries.indexed)
                          KvRow(
                            e.key.replaceAll('_', ' '),
                            _lockValue(l10n, e.value.toString()),
                            first: i == 0,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String _lockValue(AppL10n l10n, String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'unlock' || v == 'unlocked') return l10n.unlockedLabel;
    if (v == 'locked' || v == 'lock') return l10n.lockedLabel;
    return raw;
  }

  String _typeValue(AppL10n l10n, String raw) {
    final v = raw.toLowerCase();
    if (v.contains('intra')) return l10n.cellularNeighborIntra;
    if (v.contains('inter')) return l10n.cellularNeighborInter;
    return raw;
  }

  Widget _cellCard(
    AppL10n l10n,
    String title,
    List<Map<String, dynamic>> rows,
  ) {
    final t = QuartzTokens.of(context);
    String v(Map<String, dynamic> e, String key) {
      final raw = e[key];
      if (raw == null) return '—';
      final s = raw.toString().trim();
      return s.isEmpty ? '—' : s;
    }

    return QuartzCard(
      title: '$title · ${rows.length}',
      child: Column(
        children: [
          for (final (i, e) in rows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: i == 0
                  ? null
                  : BoxDecoration(
                      border: Border(top: BorderSide(color: t.border)),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PCI ${v(e, 'pci')}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ARFCN ${v(e, 'arfcn')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: t.muted,
                          ),
                        ),
                      ),
                      if (v(e, 'neighbourcell') != '—')
                        Text(
                          _typeValue(
                            l10n,
                            v(
                              e,
                              'neighbourcell',
                            ).replaceFirst('neighbourcell ', ''),
                          ),
                          style: TextStyle(fontSize: 9.5, color: t.faint),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RSRP ${v(e, 'rsrp')} dBm · RSRQ ${v(e, 'rsrq')} dB',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: t.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
