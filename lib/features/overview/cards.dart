// 概览卡片实现（一张卡一处；通用兜底卡见 registry.dart）。
import 'package:flutter/material.dart';

import '../../api/cellular.dart';
import '../../api/models.dart';
import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import '../../widgets/sparkline.dart';

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
    final theme = Theme.of(context);
    final host = snapshot?.host ?? const {};
    final name = (host['hostname'] as String?)?.isNotEmpty == true
        ? host['hostname'] as String
        : fallbackName;
    final model = (host['model'] as String?) ?? '';
    final release = (host['release'] as String?) ?? '';
    final kernel = (host['kernel'] as String?) ?? '';
    final uptime = (host['uptime'] as int?) ?? 0;

    final (d, h, m) = uptimeParts(uptime);
    final mm = m.toString().padLeft(2, '0');
    final upText = d > 0 ? l10n.runFor(d, h, mm) : l10n.runForShort(h, mm);

    return QuartzCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: QuartzColors.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      [model, release, if (kernel.isNotEmpty) '${l10n.kernelLabel} $kernel']
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: .55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (stale ? QuartzColors.warn : QuartzColors.ok).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: (stale ? QuartzColors.warn : QuartzColors.ok).withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    StatusDot(stale ? DotKind.warn : DotKind.ok),
                    if (remote) ...[
                      const Icon(Icons.cloud_outlined, size: 13, color: QuartzColors.accent),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      remote ? l10n.connectedRemote : l10n.connectedLan,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stale ? QuartzColors.warn : (remote ? QuartzColors.accent : QuartzColors.ok),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (snapshot != null && uptime > 0)
                Text(
                  upText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniBar extends StatelessWidget {
  const MiniBar({super.key, required this.pct, this.color});

  final double pct;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.brightness == Brightness.dark ? QuartzColors.darkBgBase : const Color(0xFFE4E4E9);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: track,
            color: color ?? QuartzColors.accent,
          ),
        ),
      ),
    );
  }
}

Widget systemCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final sys = s.system;
  final mem = sys['mem'] as Map<String, dynamic>? ?? const {};
  final rootfs = sys['rootfs'] as Map<String, dynamic>? ?? const {};
  final cpu = (sys['cpu_pct'] as num?) ?? 0;
  final load = (sys['load'] as List?)?.whereType<num>().toList() ?? const <num>[];
  final temp = sys['temp_c'] as num?;

  return QuartzCard(
    title: l10n.systemCardTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KvRow(l10n.cpuLabel, formatPct(cpu), first: true),
        MiniBar(pct: cpu.toDouble()),
        KvRow(
          l10n.memLabel,
          '${formatBytes((mem['used'] as num?) ?? 0)} / ${formatBytes((mem['total'] as num?) ?? 0)}',
        ),
        MiniBar(pct: ((mem['pct'] as num?) ?? 0).toDouble()),
        KvRow(
          l10n.storageLabel,
          '${formatBytes((rootfs['used'] as num?) ?? 0)} / ${formatBytes((rootfs['total'] as num?) ?? 0)}',
        ),
        MiniBar(pct: ((rootfs['pct'] as num?) ?? 0).toDouble(), color: QuartzColors.ok),
        KvRow(
          l10n.tempLabel,
          temp == null ? l10n.tempUnavailable : formatTemp(temp),
          valueColor: temp == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .35) : null,
        ),
        if (load.length >= 3)
          KvRow(l10n.loadLabel, load.take(3).map((v) => v.toStringAsFixed(2)).join(' / ')),
      ],
    ),
  );
}

Widget networkCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final theme = Theme.of(context);
  final wan = s.wan;
  final up = wan['up'] == true;
  final series = s.series;
  return QuartzCard(
    title: l10n.networkCardTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(up ? DotKind.ok : DotKind.err),
            Text(
              [
                (wan['ifname'] as String?) ?? '',
                (wan['proto'] as String?) ?? '',
                if (!up) l10n.wanDown,
              ].where((x) => x.isNotEmpty).join(' · '),
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              maskAddress((wan['ipv4'] as String?) ?? ''),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if ((wan['ipv6'] as String?)?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(l10n.ipv6Label, style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  maskAddress(wan['ipv6'] as String),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Row(
            children: [
              Text('↓ ${formatRate((wan['rx_bps'] as num?) ?? 0)}', style: theme.textTheme.bodySmall),
              const Spacer(),
              Text('↑ ${formatRate((wan['tx_bps'] as num?) ?? 0)}', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Sparkline(data: series?.$2 ?? const [], color: QuartzColors.accent),
      ],
    ),
  );
}

Widget clientsCard(BuildContext context, Snapshot s, {void Function()? onOpenAll}) {
  final l10n = AppL10n.of(context);
  final theme = Theme.of(context);
  final items = s.clientItems;
  return QuartzCard(
    title: '${l10n.clientsCardTitle} · ${s.clientsTotal}',
    trailing: onOpenAll == null
        ? null
        : GestureDetector(
            onTap: onOpenAll,
            child: const Text('›', style: TextStyle(fontSize: 16)),
          ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, c) in items.take(3).indexed)
          KvRow(
            (c['host'] as String?)?.isNotEmpty == true ? c['host'] as String : (c['mac'] as String? ?? ''),
            (c['ip'] as String?) ?? '',
            first: i == 0,
          ),
        if (items.isEmpty)
          Text(l10n.clientsEmpty, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .5))),
      ],
    ),
  );
}

Widget appsCard(BuildContext context, Snapshot s, {void Function()? onOpenAll}) {
  final l10n = AppL10n.of(context);
  final entries = s.serviceEntries;
  final theme = Theme.of(context);
  return QuartzCard(
    title: l10n.appsCardTitle,
    trailing: onOpenAll == null
        ? null
        : GestureDetector(onTap: onOpenAll, child: const Text('›', style: TextStyle(fontSize: 16))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, e) in entries.take(3).indexed)
          KvRow(
            e.$1,
            (e.$2['core'] as String?) ?? ((e.$2['running'] == true) ? l10n.running : l10n.stopped2),
            first: i == 0,
            valueMono: false,
            valueColor: theme.colorScheme.onSurface.withValues(
              alpha: e.$2['running'] == true ? .85 : .45,
            ),
          ),
        if (entries.isEmpty)
          Text(l10n.appsNone, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .5))),
      ],
    ),
  );
}

/// Docker 条件卡（安装了才显示；DESIGN 拍板 2）。
Widget dockerCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final d = s.docker!;
  final unhealthy = (d['unhealthy'] as List?)?.whereType<String>().toList() ?? const <String>[];
  return QuartzCard(
    title: l10n.dockerCardTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KvRow(l10n.dockerRunning, '${d['running'] ?? 0} / ${d['total'] ?? 0}', first: true),
        KvRow(l10n.dockerImages, '${d['images'] ?? 0}'),
        if (unhealthy.isNotEmpty)
          KvRow(
            l10n.dockerUnhealthy,
            unhealthy.join(', '),
            valueColor: QuartzColors.warn,
          ),
      ],
    ),
  );
}

/// L1 通用 KV 卡（未知 daemon 节零改版可见）。
Widget genericCard(BuildContext context, String sectionKey, List<MapEntry<String, String>> fields) {
  final title = sectionKey.replaceAll('_', ' ');
  return QuartzCard(
    title: title.isEmpty ? sectionKey : title[0].toUpperCase() + title.substring(1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, f) in fields.indexed) KvRow(f.key, f.value, first: i == 0, valueMono: false),
      ],
    ),
  );
}

/// 采集器 errors[] 弱化提示卡。
Widget collectorErrorsCard(BuildContext context, Snapshot s) {
  final l10n = AppL10n.of(context);
  final theme = Theme.of(context);
  return QuartzCard(
    title: l10n.collectorErrors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in s.errors)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(e, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .5))),
          ),
      ],
    ),
  );
}
