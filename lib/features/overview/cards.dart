// 概览卡片实现（一张卡一处；通用兜底卡见 registry.dart）。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/cellular.dart';
import '../../api/models.dart';
import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import '../../widgets/sparkline.dart';
import '../bandix/bandix_format.dart';
import '../cellular/cellular_display.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.snapshot,
    required this.fallbackName,
    this.stale = false,
    this.remote = false,
  });

  final Snapshot? snapshot;
  final String fallbackName;
  final bool stale;

  /// 当前经远程端点（tailnet）连接（W6.5 远程识别徽标）。
  final bool remote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final host = snapshot?.host ?? const {};
    final name = (host['hostname'] as String?)?.isNotEmpty == true
        ? host['hostname'] as String
        : fallbackName;
    final model = (host['model'] as String?) ?? '';
    final release = (host['release'] as String?) ?? '';
    final kernel = (host['kernel'] as String?) ?? '';
    final uptime = (host['uptime'] as int?) ?? 0;
    final wan = snapshot?.wan ?? const <String, dynamic>{};
    final up = wan['up'] == true;
    final ip = (wan['ipv4'] as String?) ?? '';

    final (d, h, m) = uptimeParts(uptime);
    final mm = m.toString().padLeft(2, '0');
    final upText = (d > 0 ? l10n.runFor(d, h, mm) : l10n.runForShort(h, mm))
        .replaceFirst(RegExp(r'^(运行|Up)\s*'), '');
    final ago = _ago(l10n, snapshot?.ts ?? 0);
    final dot = stale ? DotKind.warn : (up ? DotKind.ok : DotKind.err);

    return QuartzCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 27,
              fontWeight: FontWeight.w400,
              letterSpacing: -.3,
              height: 1.15,
              color: t.text,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            [
              model,
              release,
              if (kernel.isNotEmpty) 'Linux $kernel',
            ].where((x) => x.isNotEmpty).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: QuartzType.caption.copyWith(
              color: t.muted,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stat(context, l10n.heroUptime, upText)),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _stat(
                  context,
                  'WAN',
                  ip.isEmpty ? '—' : ip,
                  prefix: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusDot(dot, margin: const EdgeInsets.only(right: 5)),
                      if (remote)
                        QzIcon(QzIcons.cloud, size: 12, color: t.accent),
                    ],
                  ),
                  valueWidget: ip.isEmpty
                      ? null
                      : QzIpValue(
                          value: ip,
                          showLabel: l10n.ipClickToReveal,
                          hideLabel: l10n.ipClickToHide,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _stat(context, l10n.heroCollected, ago)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    Widget? prefix,
    Widget? valueWidget,
  }) {
    final t = QuartzTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: t.muted)),
        const SizedBox(height: 3),
        Row(
          children: [
            ?prefix,
            Flexible(
              child:
                  valueWidget ??
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _ago(AppL10n l10n, int ts) {
    if (ts <= 0) return '—';
    final ms = ts > 100000000000 ? ts : ts * 1000;
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (d.inSeconds < 60) return l10n.lastSeenNow;
    if (d.inMinutes < 60) return l10n.lastSeenMin(d.inMinutes);
    if (d.inHours < 24) return l10n.lastSeenHour(d.inHours);
    return l10n.lastSeenDay(d.inDays);
  }
}

Widget systemCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final sys = s.system;
  final mem = sys['mem'] as Map<String, dynamic>? ?? const {};
  final swap = sys['swap'] as Map<String, dynamic>? ?? const {};
  final rootfs = sys['rootfs'] as Map<String, dynamic>? ?? const {};
  final swapTotal = (swap['total'] as num?) ?? 0;
  final cpu = (sys['cpu_pct'] as num?) ?? 0;
  final memPct = (mem['pct'] as num?) ?? 0;
  final rootPct = (rootfs['pct'] as num?) ?? 0;
  final load =
      (sys['load'] as List?)?.whereType<num>().toList() ?? const <num>[];
  final temp = sys['temp_c'] as num?;
  final procs = sys['procs'] as num?;
  final cpuModel = (sys['cpu_model'] as String?)?.trim() ?? '';
  final cores = sys['cores'] as num?;
  final mhz = sys['cpu_mhz'] as num?;
  final maxMhz = sys['cpu_max_mhz'] as num?;
  final cpuBits = [
    if (cpuModel.isNotEmpty) cpuModel,
    if (cores != null) '${cores}C',
    if (mhz != null)
      '${_ghz(mhz)}${maxMhz != null ? ' / ${_ghz(maxMhz)}' : ''}',
  ];
  return QuartzCard(
    title: l10n.systemCardTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cpuBits.isNotEmpty) ...[
          Text(
            cpuBits.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: QuartzType.caption.copyWith(color: t.muted),
          ),
          const SizedBox(height: 2),
        ],
        KvRow(
          l10n.loadLabel,
          load.length >= 3
              ? load.take(3).map((v) => v.toStringAsFixed(2)).join(' / ')
              : '—',
          first: true,
        ),
        KvRow(l10n.cpuLabel, formatPct(cpu), pct: cpu.toDouble()),
        if (procs != null) KvRow(l10n.processesLabel, procs.toString()),
        KvRow(
          l10n.memLabel,
          '${formatBytes((mem['used'] as num?) ?? 0)} / ${formatBytes((mem['total'] as num?) ?? 0)}',
          pct: memPct.toDouble(),
        ),
        KvRow(
          l10n.mountsSwaps,
          swapTotal > 0
              ? '${formatBytes((swap['used'] as num?) ?? 0)} / ${formatBytes(swapTotal)}'
              : l10n.notEnabled,
          valueColor: swapTotal > 0 ? null : t.faint,
        ),
        KvRow(
          l10n.storageLabel,
          '${formatBytes((rootfs['used'] as num?) ?? 0)} / ${formatBytes((rootfs['total'] as num?) ?? 0)}',
          pct: rootPct.toDouble(),
        ),
        KvRow(
          l10n.tempLabel,
          temp == null ? l10n.tempUnavailable : formatTemp(temp),
          valueColor: temp == null ? t.faint : null,
          valueMono: temp != null,
        ),
      ],
    ),
  );
}

String _ghz(num mhz) {
  final ghz = mhz / 1000;
  return ghz >= 1 ? '${ghz.toStringAsFixed(1)} GHz' : '${mhz.round()} MHz';
}

Widget networkCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final wan = s.wan;
  final up = wan['up'] == true;
  final series = s.series;
  final ip4 = (wan['ipv4'] as String?) ?? '';
  final ip6 = (wan['ipv6'] as String?) ?? '';
  Widget ipValue(String value) => QzIpValue(
    value: value,
    showLabel: l10n.ipClickToReveal,
    hideLabel: l10n.ipClickToHide,
  );
  return QuartzCard(
    title: l10n.networkCardTitle,
    trailing: QzHeaderAction(
      label: '${l10n.bandixTrafficTitle} →',
      onTap: () => context.push('/apps/bandix'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(up ? DotKind.ok : DotKind.err),
            Text(
              up ? l10n.networkOnline : l10n.networkOffline,
              style: QuartzType.body.copyWith(color: t.text),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [
                  (wan['ifname'] as String?) ?? '',
                  (wan['proto'] as String?) ?? '',
                ].where((x) => x.isNotEmpty).join(' · '),
                style: QuartzType.caption.copyWith(color: t.muted),
              ),
            ),
          ],
        ),
        KvRow('IPv4', '', first: true, valueWidget: ipValue(ip4)),
        if (ip6.isNotEmpty) KvRow('IPv6', '', valueWidget: ipValue(ip6)),
        Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _rate(
                  context,
                  l10n.bandixDownload,
                  formatRate((wan['rx_bps'] as num?) ?? 0),
                  accent: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _rate(
                  context,
                  l10n.bandixUpload,
                  formatRate((wan['tx_bps'] as num?) ?? 0),
                ),
              ),
            ],
          ),
        ),
        Sparkline(data: series?.$2 ?? const [], color: t.accent),
        Text(
          l10n.networkCaption,
          style: QuartzType.caption.copyWith(color: t.faint),
        ),
      ],
    ),
  );
}

Widget _rate(
  BuildContext context,
  String label,
  String value, {
  bool accent = false,
}) {
  final t = QuartzTokens.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11.5, color: t.muted)),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: accent ? t.accent : t.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

/// 蜂窝概览卡（Dashboard QModem 卡的移动端压缩版：状态头 + 2×2 KPI）。
Widget cellularCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final c = s.cellular;
  if (c == null || !c.shown) return const SizedBox.shrink();
  final m = c.modems.first;
  final sig = m.signal;
  final dial = m.dial;
  final traffic = m.traffic;
  final cell = m.primaryCell;
  final ci = m.cellInfo;
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
  final pciCell = (cell?.pci.isNotEmpty ?? false) ? cell!.pci : (ci?.pci ?? '');
  final arfcnCell = (cell?.channel.isNotEmpty ?? false)
      ? cell!.channel
      : (ci?.arfcn ?? '');

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

  final mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: t.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  Widget rate(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 9, color: t.faint)),
      const SizedBox(height: 1),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          style: mono.copyWith(fontSize: 13, color: color),
        ),
      ),
    ],
  );

  // KPI 同行两张卡等高（信号卡多一行副文本/曲线时不把速率卡压短）。
  Widget pair(Widget left, Widget right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [left, const SizedBox(width: 8), right],
    ),
  );

  return QuartzCard(
    title: l10n.navCellular,
    trailing: QzHeaderAction(
      label: 'QModem →',
      onTap: () => context.push('/cellular'),
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
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                cellularOperatorText(l10n, m),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QuartzType.caption.copyWith(color: t.muted),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              m.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: QuartzType.caption.copyWith(color: t.faint),
            ),
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
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 8,
                        height: 5,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: i < bars ? tone : t.well,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            sub: Text(cellularSignalText(sig, compact: true)),
          ),
          kpi(
            l10n.cellularRate,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: rate(
                    l10n.bandixDownload,
                    dial?.running == true ? fmtRate(dial!.rxBps) : '—',
                    t.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: rate(
                    l10n.bandixUpload,
                    dial?.running == true ? fmtRate(dial!.txBps) : '—',
                    t.text,
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
              'PCI ${pciCell.isEmpty ? '—' : pciCell} · '
              'ARFCN ${arfcnCell.isEmpty ? '—' : arfcnCell}',
            ),
          ),
        ),
      ],
    ),
  );
}

Widget clientsCard(
  BuildContext context,
  Snapshot s, {
  void Function()? onOpenAll,
}) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final items = s.clientItems;
  return QuartzCard(
    title: '${l10n.clientsCardTitle} · ${s.clientsTotal}',
    trailing: onOpenAll == null
        ? null
        : QzHeaderAction(label: '${l10n.viewAll} →', onTap: onOpenAll),
    child: items.isEmpty
        ? Text(
            l10n.clientsEmpty,
            style: QuartzType.caption.copyWith(color: t.faint),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        l10n.clientHost,
                        style: TextStyle(fontSize: 11, color: t.faint),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        l10n.clientIp,
                        style: TextStyle(fontSize: 11, color: t.faint),
                      ),
                    ),
                    SizedBox(
                      width: 74,
                      child: Text(
                        l10n.clientLastSeen,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: t.faint),
                      ),
                    ),
                  ],
                ),
              ),
              for (final (i, c) in items.take(3).indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border: Border(top: BorderSide(color: t.border)),
                        ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          (c['host'] as String?)?.isNotEmpty == true
                              ? c['host'] as String
                              : (c['mac'] as String? ?? '—'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: QuartzType.bodyStrong.copyWith(
                            color: t.text,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          (c['ip'] as String?) ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: t.muted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 74,
                        child: Text(
                          _seenText(l10n, (c['last_seen'] as int?) ?? 0),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: t.faint),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}

String _seenText(AppL10n l10n, int lastSeen) {
  if (lastSeen <= 0) return '—';
  final (unit, n) = relativeTime(lastSeen);
  return switch (unit) {
    'now' => l10n.lastSeenNow,
    'min' => l10n.lastSeenMin(n),
    'hour' => l10n.lastSeenHour(n),
    _ => l10n.lastSeenDay(n),
  };
}

String _prettyService(String id) {
  const names = {
    'openclash': 'OpenClash',
    'qmodem': 'QModem',
    'bandix': 'Bandix',
    'dockerd': 'Docker',
    'tailscale': 'Tailscale',
    'quartz_daemon': 'Quartz daemon',
  };
  return names[id] ??
      (id.isEmpty
          ? id
          : id[0].toUpperCase() + id.substring(1).replaceAll('_', ' '));
}

Widget appsCard(
  BuildContext context,
  Snapshot s, {
  void Function()? onOpenAll,
}) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final entries = s.serviceEntries;
  final shown = entries.take(4).toList();
  Widget item((String, Map<String, dynamic>) e) {
    final running = e.$2['running'] == true;
    final core = (e.$2['core'] as String?) ?? '';
    final version = (e.$2['version'] as String?) ?? '';
    final sub = [
      core,
      version,
      running ? l10n.running : l10n.stopped2,
    ].where((x) => x.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(
              running ? DotKind.ok : DotKind.off,
              margin: const EdgeInsets.only(right: 7),
            ),
            Expanded(
              child: Text(
                _prettyService(e.$1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QuartzType.bodyStrong.copyWith(
                  color: t.text,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          sub.isEmpty ? '—' : sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            color: t.muted,
          ),
        ),
      ],
    );
  }

  return QuartzCard(
    title: l10n.servicesCardTitle,
    trailing: onOpenAll == null
        ? null
        : QzHeaderAction(label: '${l10n.viewAll} →', onTap: onOpenAll),
    child: shown.isEmpty
        ? Text(
            l10n.appsNone,
            style: QuartzType.caption.copyWith(color: t.faint),
          )
        : Column(
            children: [
              for (var i = 0; i < shown.length; i += 2)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i + 2 < shown.length ? 12 : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: item(shown[i])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: i + 1 < shown.length
                            ? item(shown[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.border)),
                ),
                child: Row(
                  children: [
                    StatusDot(
                      DotKind.ok,
                      margin: const EdgeInsets.only(right: 7),
                    ),
                    Text(
                      'quartz-daemon',
                      style: QuartzType.bodyStrong.copyWith(
                        color: t.text,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.interval}s'
                      '${s.raw['collect_ms'] is num ? ' · ${s.raw['collect_ms']}ms' : ''}',
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

/// Docker 条件卡（安装了才显示；DESIGN 拍板 2）。
Widget dockerCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final d = s.docker!;
  final available = d['available'] == true;
  final running = (d['running'] as num?)?.toInt() ?? 0;
  final total = (d['total'] as num?)?.toInt() ?? 0;
  final unhealthy =
      (d['unhealthy'] as List?)?.whereType<String>().toList() ??
      const <String>[];
  final version = (d['version'] as String?) ?? '';
  final driver = (d['driver'] as String?) ?? '';
  final root = (d['root_dir'] as String?) ?? '';
  final containers =
      (d['containers'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
      const <Map<String, dynamic>>[];
  final engineBits = [
    if (version.isNotEmpty) version,
    if (driver.isNotEmpty) driver,
  ].join(' · ');
  final stats = [
    (l10n.dockerContainers, '$running / $total'),
    (l10n.dockerImages, '${d['images'] ?? 0}'),
    (l10n.dockerNetworks, '${d['networks'] ?? 0}'),
    (l10n.dockerVolumes, '${d['volumes'] ?? 0}'),
  ];
  Widget tile((String, String) e) => Container(
    padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
    decoration: BoxDecoration(
      color: t.well.withValues(alpha: t.panelAlpha),
      borderRadius: BorderRadius.circular(QuartzRadii.sm),
      border: Border.all(color: t.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.$1, style: TextStyle(fontSize: 10.5, color: t.faint)),
        const SizedBox(height: 2),
        Text(
          e.$2,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: t.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
  Widget containerRow(Map<String, dynamic> c, {required bool first}) {
    final name = (c['name'] as String?) ?? '—';
    final image = (c['image'] as String?) ?? '';
    final state = (c['state'] as String?) ?? '';
    final status = (c['status'] as String?) ?? '';
    final kind = switch (state) {
      'running' => DotKind.ok,
      'paused' => DotKind.warn,
      'exited' || 'dead' => DotKind.err,
      _ => DotKind.off,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: t.border)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QuartzType.bodyStrong.copyWith(
                    color: t.text,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusDot(kind, margin: const EdgeInsets.only(right: 4)),
              Text(
                state.isEmpty ? '—' : state,
                style: QuartzType.caption.copyWith(
                  color: t.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [image, status].where((x) => x.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: t.faint,
            ),
          ),
        ],
      ),
    );
  }

  return QuartzCard(
    title: l10n.dockerCardTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(
              available ? DotKind.ok : DotKind.warn,
              margin: const EdgeInsets.only(right: 7),
            ),
            Text(
              available ? l10n.running : l10n.stopped2,
              style: QuartzType.body.copyWith(color: t.text),
            ),
            if (engineBits.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  engineBits,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: t.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (root.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${l10n.dockerRoot} $root',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: t.faint,
              ),
            ),
          ),
        const SizedBox(height: 8),
        for (var i = 0; i < stats.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < stats.length ? 8 : 0),
            child: Row(
              children: [
                Expanded(child: tile(stats[i])),
                const SizedBox(width: 8),
                Expanded(child: tile(stats[i + 1])),
              ],
            ),
          ),
        if (containers.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final (i, c) in containers.indexed)
            containerRow(c, first: i == 0),
        ] else if (d.containsKey('containers')) ...[
          const SizedBox(height: 8),
          Text(
            l10n.dockerNoContainers,
            style: QuartzType.caption.copyWith(color: t.faint),
          ),
        ],
        if (unhealthy.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${l10n.dockerUnhealthy}: ${unhealthy.join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: QuartzType.caption.copyWith(color: t.warn),
          ),
        ],
      ],
    ),
  );
}

/// Bandix 流量明细卡（Dashboard BandixCard 的移动端压缩版）。
Widget bandixCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  final b = s.bandix!;
  final top = s.bandixTop;
  final lim = b['limits'] as Map<String, dynamic>?;
  final conn = b['conn'] as Map<String, dynamic>?;
  final dns = b['dns'] as Map<String, dynamic>?;
  final online = (b['online'] as num?)?.toInt() ?? 0;
  final devices = (b['devices'] as num?)?.toInt() ?? 0;
  final connText = conn == null
      ? l10n.notEnabled
      : [
          '${conn['total'] ?? 0}',
          if (conn['tcp'] != null) '${l10n.tcpLabel} ${conn['tcp']}',
          if (conn['udp'] != null) '${l10n.udpLabel} ${conn['udp']}',
        ].join(' · ');
  final dnsText = dns == null
      ? l10n.notEnabled
      : formatCount((dns['queries'] as num?) ?? 0);

  Widget meta(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: t.faint)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: t.muted,
          ),
        ),
      ],
    ),
  );

  return QuartzCard(
    title: l10n.bandixTrafficTitle,
    trailing: QzHeaderAction(
      label: 'Bandix →',
      onTap: () => context.push('/apps/bandix'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(DotKind.ok),
            Text(
              l10n.bandixOnlineDevices,
              style: QuartzType.body.copyWith(color: t.text),
            ),
            const SizedBox(width: 8),
            Text(
              '$online / $devices',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            meta(l10n.connectionsLabel, connText),
            const SizedBox(width: 12),
            meta(l10n.bandixDnsQueriesLabel, dnsText),
          ],
        ),
        if (lim != null) ...[
          KvRow(
            l10n.bandixDefaultLimitLabel,
            bandixDefaultLimitText(l10n, lim),
            first: true,
            valueMono: false,
          ),
          KvRow(
            l10n.bandixWhitelistState,
            bandixPolicyCountsText(l10n, lim),
            valueMono: false,
          ),
        ],
        if (top.isNotEmpty) ...[
          const SizedBox(height: 7),
          for (final (i, it) in top.take(3).indexed)
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
                      Expanded(
                        child: Text(
                          (it['host'] as String?)?.isNotEmpty == true
                              ? it['host'] as String
                              : ((it['ip'] as String?)?.isNotEmpty == true
                                    ? it['ip'] as String
                                    : (it['mac'] as String? ?? '—')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: QuartzType.bodyStrong.copyWith(
                            fontSize: 12,
                            color: t.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      QzChip(
                        bandixDevicePolicy(l10n, it).$1,
                        kind: it['wl'] == true
                            ? QzChipKind.native
                            : (bandixDevicePolicy(l10n, it).$2
                                  ? QzChipKind.warn
                                  : QzChipKind.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '↓ ${formatRate((it['rx_r'] as num?) ?? 0)}'
                    ' · ↑ ${formatRate((it['tx_r'] as num?) ?? 0)}'
                    ' · ${l10n.bandixTotalLabel} '
                    '${formatBytes(((it['rx_b'] as num?) ?? 0) + ((it['tx_b'] as num?) ?? 0))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: t.muted,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            l10n.bandixCardNote,
            style: QuartzType.caption.copyWith(color: t.faint),
          ),
        ] else
          Text(
            l10n.bandixUnavailable,
            style: QuartzType.caption.copyWith(color: t.faint),
          ),
      ],
    ),
  );
}

/// L1 通用 KV 卡（未知 daemon 节零改版可见）。
Widget genericCard(
  BuildContext context,
  String sectionKey,
  List<MapEntry<String, String>> fields,
) {
  final title = sectionKey.replaceAll('_', ' ');
  return QuartzCard(
    title: title.isEmpty
        ? sectionKey
        : title[0].toUpperCase() + title.substring(1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, f) in fields.indexed)
          KvRow(f.key, f.value, first: i == 0, valueMono: false),
      ],
    ),
  );
}

/// 采集器 errors[] 弱化提示卡。
Widget collectorErrorsCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final t = QuartzTokens.of(context);
  return QuartzCard(
    title: l10n.collectorErrors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in s.errors)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(e, style: QuartzType.caption.copyWith(color: t.faint)),
          ),
      ],
    ),
  );
}
