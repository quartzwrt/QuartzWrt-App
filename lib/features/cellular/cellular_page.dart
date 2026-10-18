// 蜂窝 tab · 首页（W6.12；UI-DESIGN 定案：模组概览 + 信号块 + 拨号卡 + 入口宫格）。
//
// 数据面 = 快照 `cellular`（契约 §3.9，与 Dashboard 卡同源）；动作面 = app-api
// `qmodem.*` 转发条目（拨号/断开/重拨）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/cellular.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../../widgets/sparkline.dart';
import '../actions/actions.dart';

class CellularPage extends ConsumerStatefulWidget {
  const CellularPage({super.key});

  @override
  ConsumerState<CellularPage> createState() => _CellularPageState();
}

class _CellularPageState extends ConsumerState<CellularPage> {
  /// 多模组切换（顶部 segmented；仅 1 个模组时不显示）。
  int _modemIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final cellular = snap?.cellular;

    if (cellular == null || !cellular.shown) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navCellular, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.cellularUnavailableBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .5)),
            ),
          ),
        ),
      );
    }

    final idx = _modemIndex.clamp(0, cellular.modems.length - 1);
    final modem = cellular.modems[idx];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCellular, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          if (modem.traffic?.available == true)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  l10n.cellularMonthUsage(fmtBytes(modem.traffic!.rxBytes)),
                  style: const TextStyle(color: QuartzColors.accent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(snapshotProvider.notifier).refreshNow(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (cellular.modems.length > 1) ...[
              _modemSwitcher(cellular, idx),
              const SizedBox(height: 12),
            ],
            _signalCard(context, modem),
            _summaryCard(context, modem),
            _dialCard(context, modem),
            _entryGrid(context, modem),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 多模组顶部切换器（决策 D8′）。
  Widget _modemSwitcher(Cellular cellular, int idx) {
    return SegmentBar<int>(
      values: [for (var i = 0; i < cellular.modems.length; i++) i],
      selected: idx,
      labelOf: (i) {
        final m = cellular.modems[i];
        return m.model.isNotEmpty ? '${m.id} · ${m.model}' : m.id;
      },
      onChanged: (i) => setState(() => _modemIndex = i),
    );
  }

  /// 信号块：质量段条 + 四指标 + RSRP 历史曲线（缺失项按能力隐藏，不展示 0）。
  Widget _signalCard(BuildContext context, CellularModem m) {
    final l10n = AppL10n.of(context);
    final sig = m.signal;
    final tier = qualityTier(sig?.qualityPct);
    final bars = qualityBars(sig?.qualityPct);
    final tone = switch (tier) {
      'good' => QuartzColors.ok,
      'fair' => QuartzColors.warn,
      'poor' => QuartzColors.err,
      _ => null,
    };
    return QuartzCard(
      title: [
        l10n.cellularSignal,
        if (m.networkMode.isNotEmpty) m.networkMode,
        if (m.operator.isNotEmpty) m.operator,
      ].join(' · '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.cellularSignalQuality, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 10),
              _bars(bars, tone),
              const Spacer(),
              if (sig?.rsrp != null)
                Text(
                  '${sig!.rsrp!.toStringAsFixed(0)} dBm${tier != null ? ' · ${_tierText(l10n, tier)}' : ''}',
                  style: TextStyle(color: tone ?? QuartzColors.accent, fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              if (tier == null && m.capabilities.currentBand == false)
                Text(l10n.cellularSignalUnsupported, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          _metricStrip(context, sig),
          if (sig?.series != null && sig!.series!.rsrp.length > 1) ...[
            const SizedBox(height: 8),
            Sparkline(data: sig.series!.rsrp, color: QuartzColors.ok, height: 34),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cellularRsrpHistory, style: const TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF))),
                Text(
                  l10n.cellularSeriesHint('${sig.series!.step}', '${sig.series!.rsrp.length}'),
                  style: const TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bars(int filled, Color? tone) {
    final on = tone ?? QuartzColors.accent;
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 15,
            height: 8,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < filled ? on : on.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  String _tierText(AppL10n l10n, String tier) => switch (tier) {
        'good' => l10n.cellularQualityGood,
        'fair' => l10n.cellularQualityFair,
        _ => l10n.cellularQualityPoor,
      };

  /// 四指标条（RSRP/RSRQ/SINR/RSSI；缺失的单元格显示占位符）。
  Widget _metricStrip(BuildContext context, CellularSignal? sig) {
    final l10n = AppL10n.of(context);
    Widget cell(String label, String? value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0x8CFFFFFF))),
                const SizedBox(height: 2),
                Text(value ?? l10n.unknownValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          cell('RSRP', sig?.rsrp == null ? null : '${sig!.rsrp!.toStringAsFixed(0)} dBm'),
          cell('RSRQ', sig?.rsrq == null ? null : '${sig!.rsrq!.toStringAsFixed(0)} dB'),
          cell('SINR', sig?.sinr == null ? null : '${sig!.sinr!.toStringAsFixed(0)} dB'),
          cell('RSSI', sig?.rssi == null ? null : '${sig!.rssi!.toStringAsFixed(0)} dBm'),
        ],
      ),
    );
  }

  /// 网络 · SIM 摘要 + 服务小区。
  Widget _summaryCard(BuildContext context, CellularModem m) {
    final l10n = AppL10n.of(context);
    final cell = m.primaryCell;
    return QuartzCard(
      title: l10n.cellularNetworkSim,
      child: Column(
        children: [
          if (cell != null)
            KvRow(
              l10n.cellularServingCell,
              [
                cell.band,
                if (cell.channel.isNotEmpty) 'ARFCN ${cell.channel}',
                if (cell.pci.isNotEmpty) 'PCI ${cell.pci}',
                if (cell.dlBandwidth.isNotEmpty) '${cell.dlBandwidth} MHz',
              ].join(' · '),
              first: true,
            ),
          if (m.sim != null)
            KvRow(
              l10n.cellularSimLabel,
              [m.sim!.status, if (m.sim!.slot.isNotEmpty) '${l10n.cellularSimSlot} ${m.sim!.slot}'].join(' · '),
              first: cell == null,
              valueMono: false,
            ),
          if (m.firmware.isNotEmpty)
            KvRow(l10n.cellularFirmware, m.firmware, first: cell == null && m.sim == null),
        ],
      ),
    );
  }

  /// 拨号卡：状态 · 时长 · 地址（打码，点按展开）· 速率 · 动作。
  Widget _dialCard(BuildContext context, CellularModem m) {
    final l10n = AppL10n.of(context);
    final d = m.dial;
    final running = d?.running ?? false;
    return QuartzCard(
      title: l10n.cellularDial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: running ? QuartzColors.ok : Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                running ? l10n.cellularDialConnected : l10n.cellularDialDisconnected,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (d != null && d.ipv4.isNotEmpty) _maskedAddress(d.ipv4),
            ],
          ),
          if (running && d != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('↓ ${fmtRate(d.rxBps)}', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Text('↑ ${fmtRate(d.txBps)}', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  running ? l10n.cellularHang : l10n.cellularDialNow,
                  danger: running,
                  onTap: () => _runDial(running ? 'qmodem.hang' : 'qmodem.dial', running ? l10n.cellularHang : l10n.cellularDialNow, m),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  l10n.cellularRedial,
                  onTap: () => _runDial('qmodem.redial', l10n.cellularRedial, m),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, {bool danger = false, required VoidCallback onTap}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? QuartzColors.err.withValues(alpha: .12) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
              border: Border.all(color: danger ? QuartzColors.err.withValues(alpha: .35) : theme.dividerColor.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: danger ? QuartzColors.err : null),
            ),
          ),
        );
      },
    );
  }

  Future<void> _runDial(String actionId, String label, CellularModem m) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    if (actionId != 'qmodem.dial') {
      final ok = await showConfirmSheet(
        context,
        title: label,
        body: actionId == 'qmodem.hang' ? l10n.cellularHangWarning : l10n.cellularRedialWarning,
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
      );
      if (!ok) return;
    }
    final spec = ActionSpec(
      id: actionId,
      label: label,
      argsOf: () => {'config_section': m.id},
    );
    final r = await runAction(tm, spec);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }

  /// 入口宫格：与 qmodem 网页端菜单一一对应（6 格，均已实现）。
  Widget _entryGrid(BuildContext context, CellularModem m) {
    final l10n = AppL10n.of(context);
    final tiles = <(IconData, String, String)>[
      (Icons.wifi_tethering, l10n.cellularEntryNetwork, '/cellular/network'),
      (Icons.sim_card_outlined, l10n.cellularEntrySim, '/cellular/sim'),
      (Icons.sms_outlined, l10n.cellularEntrySms, '/cellular/sms'),
      (Icons.terminal, l10n.cellularEntryAt, '/cellular/at'),
      (Icons.tune, l10n.cellularAdvanced, '/cellular/advanced'),
      (Icons.article_outlined, l10n.cellularEntryLog, '/cellular/log'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 0 ? 10 : 0),
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(child: _tile(context, tiles[row * 3 + col].$1, tiles[row * 3 + col].$2, () => context.push(tiles[row * 3 + col].$3))),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
          border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: .55)),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// 地址默认打码，点按展开/收起（决策：隐私友好；长按可未来扩展为复制）。
  Widget _maskedAddress(String addr) {
    return _RevealableAddress(addr: addr);
  }
}

class _RevealableAddress extends StatefulWidget {
  const _RevealableAddress({required this.addr});

  final String addr;

  @override
  State<_RevealableAddress> createState() => _RevealableAddressState();
}

class _RevealableAddressState extends State<_RevealableAddress> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _shown = !_shown),
      child: Text(
        _shown ? widget.addr : maskAddress(widget.addr),
        style: TextStyle(
          fontSize: 12.5,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: _shown ? .85 : .55),
          decoration: _shown ? null : TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dashed,
          decorationColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
        ),
      ),
    );
  }
}
