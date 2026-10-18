// 蜂窝 · 网络配置（W6.12）：网络偏好（3G/4G/5G 多选）+ 频段锁定（只读回显 + 快捷锁定）
// + 高级（USB 拨号模式标注为危险，与网页端同源字段）。
//
// 数据面：快照 `settings`（概览级）；写入前用页面级读条目取当前值（`qmodem.lockband`
// / `qmodem.network_prefer`）。语义（读上游源码核实）：`set_network_prefer` 收**数组**；
// `set_lockband` 收 `{band_class, lock_band}` 方言；`set_mode` 是 **USB 拨号模式**。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/cellular.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../actions/actions.dart';
import 'qmodem_client.dart';

class CellularNetworkPage extends ConsumerStatefulWidget {
  const CellularNetworkPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularNetworkPage> createState() => _CellularNetworkPageState();
}

class _CellularNetworkPageState extends ConsumerState<CellularNetworkPage> {
  static const _rats = ['3G', '4G', '5G'];

  Set<String> _prefer = {};
  bool _loaded = false;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 页面级读：当前网络偏好（`get_network_prefer` 标志位对象或 `{prefer}`）。
  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final r = await client.call('qmodem.network_prefer', section: widget.section);
    final prefer = <String>{};
    if (r.ok) {
      final m = r.map;
      final flags = m['network_prefer'];
      if (flags is Map) {
        for (final k in _rats) {
          final v = flags[k];
          if (v == '1' || v == 1 || v == true) prefer.add(k);
        }
      } else if (m['prefer'] is String) {
        final p = (m['prefer'] as String).toUpperCase();
        for (final k in _rats) {
          if (p.contains(k)) prefer.add(k);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (r.ok) _prefer = prefer;
      _error = r.ok ? '' : r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data?.cellular;
    CellularModem? modem;
    for (final m in snap?.modems ?? const <CellularModem>[]) {
      if (m.id == widget.section) modem = m;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellularEntryNetwork, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (!_loaded)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else ...[
            if (_error.isNotEmpty) InfoBanner(title: l10n.actionFailed(_error), body: l10n.cellularSettingsHint),
            QuartzCard(
              title: l10n.cellularNetworkPrefer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in _rats)
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      value: _prefer.contains(r),
                      onChanged: _busy ? null : (v) => setState(() => v ? _prefer.add(r) : _prefer.remove(r)),
                    ),
                  const SizedBox(height: 4),
                  Text(l10n.cellularNetworkPreferHint, style: const TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF))),
                  const SizedBox(height: 10),
                  _applyButton(
                    l10n,
                    enabled: _prefer.isNotEmpty && !_busy,
                    onTap: () => _applyPrefer(),
                  ),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.cellularLockband,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((modem?.settings?.lockband ?? const []).isEmpty)
                    Text(l10n.cellularLockbandUnlocked, style: const TextStyle(fontSize: 13))
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final b in modem!.settings!.lockband)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: QuartzColors.accent.withValues(alpha: .16),
                              border: Border.all(color: QuartzColors.accent.withValues(alpha: .45)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(b, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(l10n.cellularLockbandHint, style: const TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF))),
                  const SizedBox(height: 10),
                  _applyButton(
                    l10n,
                    label: l10n.cellularLockbandUnlock,
                    enabled: (modem?.settings?.lockband ?? const []).isNotEmpty && !_busy,
                    danger: true,
                    onTap: () => _applyLockbandUnlock(),
                  ),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.cellularAdvanced,
              child: Column(
                children: [
                  KvRow(l10n.cellularUsbMode, modem?.settings?.usbMode ?? l10n.unknownValue, first: true),
                  KvRow(l10n.cellularTemp, modem?.tempC == null ? l10n.unknownValue : '${modem!.tempC!.toStringAsFixed(1)} °C'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _applyButton(AppL10n l10n, {String? label, required bool enabled, bool danger = false, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: danger ? QuartzColors.err.withValues(alpha: .9) : null,
        ),
        child: Text(label ?? l10n.cellularApplyPrefer),
      ),
    );
  }

  /// 网络偏好：数组下发（`params` 为 JSON 字符串，app-api 侧结构校验）。
  Future<void> _applyPrefer() async {
    final order = ['3G', '4G', '5G'];
    final arr = order.where(_prefer.contains).toList();
    await _send(
      'qmodem.set_network_prefer',
      params: '[${arr.map((e) => '"$e"').join(',')}]',
      label: AppL10n.of(context).cellularApplyPrefer,
      danger: false,
    );
  }

  /// 频段解锁：`{band_class, lock_band:"0"}`（各厂商以 0/空表示解锁）。
  Future<void> _applyLockbandUnlock() async {
    final l10n = AppL10n.of(context);
    await _send(
      'qmodem.set_lockband',
      params: '{"band_class":"LTE","lock_band":"0"}',
      label: '${l10n.cellularLockbandUnlock} · LTE',
      danger: true,
    );
  }

  Future<void> _send(String actionId, {required String params, required String label, required bool danger}) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    if (danger) {
      final ok = await showConfirmSheet(
        context,
        title: label,
        body: l10n.cellularDangerWarning,
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    final spec = ActionSpec(
      id: actionId,
      label: label,
      danger: danger,
      argsOf: () => {'config_section': widget.section, 'params': params},
    );
    final r = await runAction(tm, spec);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    if (r.ok) {
      await _load();
      ref.read(snapshotProvider.notifier).refreshNow();
    }
  }
}
