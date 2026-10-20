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
import 'cellular_display.dart';

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
    final t = QuartzTokens.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final cellular = snap?.cellular;

    if (cellular == null || !cellular.shown) {
      return Scaffold(
        appBar: QzAppBar(titleText: l10n.navCellular),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.cellularUnavailableBody,
              textAlign: TextAlign.center,
              style: QuartzType.sub.copyWith(color: t.faint),
            ),
          ),
        ),
      );
    }

    final idx = _modemIndex.clamp(0, cellular.modems.length - 1);
    final modem = cellular.modems[idx];

    return Scaffold(
      appBar: QzAppBar(
        titleText: l10n.navCellular,
        trailingText: modem.traffic?.available == true
            ? l10n.cellularMonthUsage(fmtBytes(modem.traffic!.rxBytes))
            : null,
      ),
      body: QzRefresh(
        onRefresh: () => ref.read(snapshotProvider.notifier).refreshNow(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (cellular.modems.length > 1) ...[
              _modemSwitcher(cellular, idx),
              const SizedBox(height: 12),
            ],
            _dashboardCard(
              context,
              modem,
              wanIp: (snap?.wan['ifname'] as String? ?? '').startsWith('wwan')
                  ? (snap?.wan['ipv4'] as String? ?? '')
                  : '',
            ),
            _dialActions(context, modem),
            _entryGroups(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 多模组顶部切换器（决策 D8′）。
  Widget _modemSwitcher(Cellular cellular, int idx) {
    return QzSegmented<int>(
      values: [for (var i = 0; i < cellular.modems.length; i++) i],
      selected: idx,
      labelOf: (i) {
        final m = cellular.modems[i];
        return m.model.isNotEmpty ? '${m.id} · ${m.model}' : m.id;
      },
      onChanged: (i) => setState(() => _modemIndex = i),
      margin: const EdgeInsets.only(bottom: 12),
    );
  }

  /// Dashboard QModem 卡：状态头 + KPI 2×2 + Radio/Cell & SIM/Connection/Hardware。
  Widget _dashboardCard(
    BuildContext context,
    CellularModem m, {
    String wanIp = '',
  }) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final sig = m.signal;
    final cell = m.primaryCell;
    final ci = m.cellInfo;
    final dial = m.dial;
    final traffic = m.traffic;
    final sim = m.sim;
    final settings = m.settings;
    final tier = qualityTier(sig?.qualityPct);
    final bars = qualityBars(sig?.qualityPct);
    final tone = switch (tier) {
      'good' => t.ok,
      'fair' => t.warn,
      'poor' => t.err,
      _ => t.muted,
    };
    final bandRaw = (cell?.band.isNotEmpty ?? false)
        ? cell!.band
        : (ci?.band ?? '');
    final band = bandRaw.replaceFirst(RegExp(r'^(LTE|NR)\s+'), '');
    final mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final monoSmall = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      color: t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // cell_info（结构字段）优先，get_current_band（实时小区）兜底。
    String pick(String primary, String fallback) =>
        primary.isNotEmpty ? primary : fallback;
    String dash(String v) => v.isEmpty ? '—' : v;
    String simStatusValue(String v) =>
        v.toLowerCase() == 'ready' ? l10n.simStatusReady : v;
    String yesNo(bool v) => v ? l10n.yesLabel : l10n.noLabel;
    String connectStatusValue() {
      final raw = m.connectStatus.trim();
      final lower = raw.toLowerCase();
      if (lower == 'yes' || lower == 'connected') {
        return l10n.cellularDialConnected;
      }
      if (lower == 'no') return l10n.cellularDialDisconnected;
      if (raw.isNotEmpty) return raw;
      return dial?.running == true ? l10n.cellularDialConnected : '';
    }

    final ulBw = pick(ci?.ulBandwidth ?? '', cell?.ulBandwidth ?? '');
    final dlBw = pick(ci?.dlBandwidth ?? '', cell?.dlBandwidth ?? '');
    final bwText = ulBw.isEmpty && dlBw.isEmpty
        ? '—'
        : '${dash(ulBw)} / ${dash(dlBw)} MHz';
    final mccMnc = (ci?.mcc.isNotEmpty ?? false)
        ? '${ci!.mcc} / ${dash(ci.mnc)}'
        : '—';
    final scs = pick(ci?.scs ?? '', cell?.scs ?? '');
    final ipv4 = dial?.ipv4.isNotEmpty == true ? dial!.ipv4 : wanIp;

    Widget kpi(String label, Widget value, {Widget? sub}) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        decoration: BoxDecoration(
          color: t.well.withValues(alpha: t.panelAlpha),
          borderRadius: BorderRadius.circular(QuartzRadii.sm),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: t.faint,
                letterSpacing: .4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            value,
            if (sub != null) ...[
              const SizedBox(height: 3),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                  color: t.faint,
                ),
                child: sub,
              ),
            ],
          ],
        ),
      ),
    );

    // KPI 同行两张卡等高（信号卡含两行副文本 + 曲线）。
    Widget pair(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(width: 8), right],
      ),
    );

    Widget kv(String label, String value, {Widget? valueWidget}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: QuartzType.caption.copyWith(color: t.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value.isEmpty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: monoSmall,
                  ),
            ),
          ),
        ],
      ),
    );

    Widget section(String title, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
            color: t.faint,
          ),
        ),
        ...rows,
      ],
    );

    return QuartzCard(
      title: 'QModem · ${m.title}',
      trailing: QzHeaderAction(
        label: '${l10n.cellularAdvanced} →',
        onTap: () => context.push('/cellular/advanced'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(m.registered ? DotKind.ok : DotKind.err),
              Text(
                m.registered
                    ? l10n.cellularRegistered
                    : l10n.cellularNotRegistered,
                style: QuartzType.body.copyWith(color: t.text),
              ),
              if (m.networkMode.isNotEmpty) ...[
                const SizedBox(width: 7),
                QzChip(m.networkMode, kind: QzChipKind.muted),
              ],
              if (cellularOperatorText(l10n, m).isNotEmpty) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    cellularOperatorText(l10n, m),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QuartzType.caption.copyWith(color: t.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          pair(
            kpi(
              l10n.cellularSignal,
              Row(
                children: [
                  Text(
                    sig?.rsrp == null ? '—' : sig!.rsrp!.toStringAsFixed(0),
                    style: mono.copyWith(fontSize: 19, color: tone),
                  ),
                  const SizedBox(width: 3),
                  Text('dBm', style: TextStyle(fontSize: 9.5, color: t.faint)),
                  const Spacer(),
                  _bars(bars, tone),
                ],
              ),
              sub: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cellularSignalText(sig)),
                  if (sig?.series != null && sig!.series!.rsrp.length > 1) ...[
                    const SizedBox(height: 3),
                    Sparkline(data: sig.series!.rsrp, color: tone, height: 26),
                  ],
                ],
              ),
            ),
            kpi(
              l10n.cellularRate,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _rateCell(
                      l10n.bandixDownload,
                      dial?.running == true ? fmtRate(dial!.rxBps) : '—',
                      mono.copyWith(fontSize: 14, color: t.accent),
                      t,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _rateCell(
                      l10n.bandixUpload,
                      dial?.running == true ? fmtRate(dial!.txBps) : '—',
                      mono.copyWith(fontSize: 14),
                      t,
                    ),
                  ),
                ],
              ),
              sub: Text(
                dial?.running == true
                    ? l10n.cellularDialConnected
                    : l10n.cellularDialDisconnected,
              ),
            ),
          ),
          const SizedBox(height: 8),
          pair(
            kpi(
              l10n.cellularThisMonth,
              Text(
                traffic?.available == true ? fmtBytes(traffic!.rxBytes) : '—',
                style: mono.copyWith(fontSize: 17),
              ),
              sub: Text(
                traffic?.available == true
                    ? '${fmtBytes(traffic!.txBytes)} ↑ · ${cellularResetText(l10n, traffic)}'
                    : l10n.unknownValue,
              ),
            ),
            kpi(
              l10n.cellularServingCell,
              Text(
                band.isEmpty ? '—' : band,
                style: mono.copyWith(fontSize: 19, fontWeight: FontWeight.w500),
              ),
              sub: Text(
                'PCI ${dash(pick(ci?.pci ?? '', cell?.pci ?? ''))} · '
                'ARFCN ${dash(pick(ci?.arfcn ?? '', cell?.channel ?? ''))}',
              ),
            ),
          ),
          section(l10n.cellularRadioSection, [
            kv(l10n.cellularBandLabel, dash(bandRaw)),
            kv(
              l10n.cellularArfcnLabel,
              pick(ci?.arfcn ?? '', cell?.channel ?? ''),
            ),
            kv(l10n.cellularPciLabel, pick(ci?.pci ?? '', cell?.pci ?? '')),
            kv(l10n.cellularBwLabel, bwText),
            kv(l10n.cellularScsLabel, scs.isEmpty ? '' : '$scs kHz'),
            kv(
              l10n.cellularDuplexLabel,
              pick(ci?.duplex ?? '', cell?.rat ?? ''),
            ),
          ]),
          section(l10n.cellularCellSimSection, [
            kv(l10n.cellularMccMncLabel, mccMnc),
            kv(l10n.cellularTacLabel, ci?.tac ?? ''),
            kv(l10n.cellularCellIdLabel, ci?.cellId ?? ''),
            kv(l10n.cellularSimStatusLabel, simStatusValue(sim?.status ?? '')),
            kv(l10n.cellularSimSlotLabel, sim?.slot ?? ''),
            kv(l10n.cellularSwitchableLabel, yesNo(sim?.switchable == true)),
          ]),
          section(l10n.cellularConnectionSection, [
            kv(
              'IPv4',
              ipv4,
              valueWidget: QzIpValue(
                value: ipv4,
                showLabel: l10n.ipClickToReveal,
                hideLabel: l10n.ipClickToHide,
                style: monoSmall,
              ),
            ),
            kv(l10n.cellularCqiLabel, cellularCqiText(m)),
            kv(l10n.cellularAmbrLabel, cellularAmbrText(m)),
            kv(l10n.cellularUsbMode, settings?.usbMode ?? ''),
            kv(l10n.cellularUsbSpeed, cellularUsbSpeedText(m)),
            kv(l10n.cellularPreferenceLabel, settings?.prefer ?? ''),
          ]),
          section(l10n.cellularHardwareSection, [
            kv(l10n.cellularManufacturerLabel, _capitalize(m.vendor)),
            kv(l10n.cellularRevisionLabel, m.firmware),
            kv(l10n.cellularAtPort, m.atPort),
            kv(
              l10n.cellularVoltageLabel,
              m.voltageMv == null ? '—' : '${m.voltageMv} mV',
            ),
            kv(
              l10n.cellularTemp,
              m.tempC == null ? '—' : '${m.tempC!.toStringAsFixed(1)} °C',
            ),
            kv(l10n.cellularConnectStatusLabel, connectStatusValue()),
          ]),
        ],
      ),
    );
  }

  Widget _rateCell(
    String label,
    String value,
    TextStyle style,
    QuartzTokens t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: t.faint)),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: style),
        ),
      ],
    );
  }

  Widget _bars(int filled, Color on) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 9,
            height: 6,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: i < filled ? on : on.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _dialActions(BuildContext context, CellularModem m) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final running = m.dial?.running == true;
    return QuartzCard(
      title: l10n.cellularDial,
      child: Column(
        children: [
          Row(
            children: [
              StatusDot(running ? DotKind.ok : DotKind.off),
              Text(
                running
                    ? l10n.cellularDialConnected
                    : l10n.cellularDialDisconnected,
                style: QuartzType.bodyStrong.copyWith(color: t.text),
              ),
              const Spacer(),
              if (m.dial?.ipv4.isNotEmpty == true)
                QzIpValue(
                  value: m.dial!.ipv4,
                  showLabel: l10n.ipClickToReveal,
                  hideLabel: l10n.ipClickToHide,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: t.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: QzButton(
                  label: running ? l10n.cellularHang : l10n.cellularDialNow,
                  kind: running ? QzButtonKind.danger : QzButtonKind.primary,
                  expand: true,
                  onPressed: () => _runDial(
                    running ? 'qmodem.hang' : 'qmodem.dial',
                    running ? l10n.cellularHang : l10n.cellularDialNow,
                    m,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QzButton(
                  label: l10n.cellularRedial,
                  kind: QzButtonKind.plain,
                  expand: true,
                  onPressed: () =>
                      _runDial('qmodem.redial', l10n.cellularRedial, m),
                ),
              ),
            ],
          ),
        ],
      ),
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
        body: actionId == 'qmodem.hang'
            ? l10n.cellularHangWarning
            : l10n.cellularRedialWarning,
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
    showQzToast(
      context,
      r.ok ? l10n.actionDone : l10n.actionFailed(r.message),
      kind: r.ok ? QzToastKind.ok : QzToastKind.err,
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }

  /// 入口层级对齐 qmodem 网页端：拨号 / 高级模组设置 / 短信与 SIM。
  /// 模组信息与拨号概览就是本页顶部，不再重复入口。
  Widget _entryGroups(BuildContext context) {
    final l10n = AppL10n.of(context);
    QzListRow row({
      required String title,
      required String subtitle,
      required String route,
      bool first = false,
    }) => QzListRow(
      first: first,
      compact: true,
      title: title,
      subtitle: subtitle,
      onTap: () => context.push(route),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QzSectionLabel(l10n.cellularGroupDial),
          QzListGroup(
            margin: const EdgeInsets.only(bottom: 14),
            children: [
              row(
                title: l10n.cellularEntryLog,
                subtitle: l10n.cellularEntryLogSub,
                route: '/cellular/log',
                first: true,
              ),
            ],
          ),
          QzSectionLabel(l10n.cellularGroupAdvanced),
          QzListGroup(
            margin: const EdgeInsets.only(bottom: 14),
            children: [
              row(
                title: l10n.cellularEntryNetwork,
                subtitle: l10n.cellularEntryNetworkSub,
                route: '/cellular/network',
                first: true,
              ),
              row(
                title: l10n.cellularEntryNeighbor,
                subtitle: l10n.cellularEntryNeighborSub,
                route: '/cellular/neighbor',
              ),
              row(
                title: l10n.cellularEntryAt,
                subtitle: l10n.cellularEntryAtSub,
                route: '/cellular/at',
              ),
              row(
                title: l10n.cellularEntryMaintenance,
                subtitle: l10n.cellularEntryMaintenanceSub,
                route: '/cellular/advanced',
              ),
            ],
          ),
          QzSectionLabel(l10n.cellularGroupMessages),
          QzListGroup(
            margin: const EdgeInsets.only(bottom: 8),
            children: [
              row(
                title: l10n.cellularEntrySms,
                subtitle: l10n.cellularEntrySmsSub,
                route: '/cellular/sms',
                first: true,
              ),
              row(
                title: l10n.cellularEntrySim,
                subtitle: l10n.cellularEntrySimSub,
                route: '/cellular/sim',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _capitalize(String v) =>
    v.isEmpty ? '' : v[0].toUpperCase() + v.substring(1);
