// 蜂窝 · SIM 管理（W6.13）：槽位查看/切换（能力协商：`supportSwitch=0` → 只读）
// + 短信存储用量。切换会断网 → 危险确认层。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularSimPage extends ConsumerStatefulWidget {
  const CellularSimPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularSimPage> createState() => _CellularSimPageState();
}

class _CellularSimPageState extends ConsumerState<CellularSimPage> {
  bool _loaded = false;
  bool _busy = false;
  bool _switchable = false;
  String _slot = '';
  int _storeUsed = 0;
  int _storeTotal = 0;
  String _storeMem = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final caps = await client.call(
      'qmodem.sim_switch_capabilities',
      section: widget.section,
    );
    final slot = await client.call('qmodem.sim_slot', section: widget.section);
    final store = await client.call(
      'qmodem.sms_storage_get',
      section: widget.section,
    );
    final mem = <String, dynamic>{
      if (store.map['SM'] is Map) 'SM': store.map['SM'],
      if (store.map['ME'] is Map) 'ME': store.map['ME'],
    };
    var used = 0;
    var total = 0;
    var memName = (store.map['configured'] as String?) ?? '';
    for (final e in mem.entries) {
      final m = e.value as Map;
      final u = (m['used'] as num?)?.toInt() ?? 0;
      final t = (m['total'] as num?)?.toInt() ?? 0;
      if (t > 0) {
        used += u;
        total += t;
        if (memName.isEmpty) memName = e.key;
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _switchable =
          caps.map['supportSwitch'] == '1' || caps.map['supportSwitch'] == true;
      _slot =
          (slot.map['slot'] as String?) ??
          (slot.map['sim_slot'] as String?) ??
          '';
      _storeUsed = used;
      _storeTotal = total;
      _storeMem = memName;
      _error = caps.ok && slot.ok
          ? ''
          : (caps.message.isNotEmpty ? caps.message : slot.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data?.cellular;
    final sim = snap?.modems
        .where((m) => m.id == widget.section)
        .firstOrNull
        ?.sim;

    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.cellularEntrySim,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: !_loaded
          ? const Center(child: QzSpinner(size: 22))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (!_switchable)
                  InfoBanner(
                    title: l10n.cellularSimNoSwitchTitle,
                    body: l10n.cellularSimNoSwitchBody,
                  ),
                QuartzCard(
                  title: l10n.cellularSimLabel,
                  child: Column(
                    children: [
                      KvRow(
                        l10n.cellularSimStatus,
                        sim?.status.isNotEmpty == true
                            ? sim!.status
                            : l10n.unknownValue,
                        first: true,
                        valueMono: false,
                      ),
                      KvRow(
                        l10n.cellularSimSlot,
                        _slot.isEmpty ? l10n.unknownValue : _slot,
                      ),
                      if (_storeTotal > 0)
                        KvRow(
                          l10n.cellularSmsStorage,
                          '$_storeMem · $_storeUsed / $_storeTotal',
                        ),
                    ],
                  ),
                ),
                if (_switchable)
                  QuartzCard(
                    title: l10n.cellularSimSwitch,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in const ['1', '2'])
                          QzPressable(
                            highlight: true,
                            onTap: _busy
                                ? null
                                : () => setState(() => _slot = s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  QzIcon(
                                    _slot == s ? QzIcons.check : QzIcons.dot,
                                    size: 18,
                                    color: _slot == s
                                        ? QuartzColors.accent
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${l10n.cellularSimSlot} $s',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        QzButton(
                          label: l10n.cellularSimSwitchApply,
                          kind: QzButtonKind.danger,
                          expand: true,
                          onPressed: _busy ? null : () => _switchSlot(),
                        ),
                      ],
                    ),
                  ),
                if (_error.isNotEmpty)
                  InfoBanner(
                    title: l10n.actionFailed(_error),
                    body: l10n.cellularSettingsHint,
                  ),
              ],
            ),
    );
  }

  Future<void> _switchSlot() async {
    final l10n = AppL10n.of(context);
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.cellularSimSwitchConfirm(_slot),
      body: l10n.cellularSimSwitchWarning,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final r = await client.call(
      'qmodem.set_sim_slot',
      section: widget.section,
      args: {'slot': _slot},
    );
    if (!mounted) return;
    setState(() => _busy = false);
    showQzToast(
      context,
      r.ok ? l10n.actionDone : l10n.actionFailed(r.message),
      kind: r.ok ? QzToastKind.ok : QzToastKind.err,
    );
    if (r.ok) {
      await _load();
      ref.read(snapshotProvider.notifier).refreshNow();
    }
  }
}
