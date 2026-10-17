// 流量明细页（WP-6 L3；WP-8 bridge DESIGN §7 L3 = 设备 Top / 连接 / DNS 摘要 + 动作）。
//
// 数据面 = daemon 快照 `snapshot.bandix`（契约 §3.7；与 Dashboard 同字节、5s 刷新，
// 下拉即取最新）；动作面 = WP-5「ubus 转发项」（bandix.*）。不复制网页设置表单全字段
// （port/iface/data_dir 等引擎参数留网页——bridge DESIGN §7「明确不做」）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'bandix_sheets.dart';

class BandixPage extends ConsumerWidget {
  const BandixPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final b = snap?.bandix;
    final available = snap?.bandixAvailable == true;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.bandixTrafficTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(snapshotProvider.notifier).refreshNow(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (!available)
              QuartzCard(
                child: Text(
                  b == null ? l10n.bandixUnavailable : l10n.bandixNotEnabled,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                        height: 1.6,
                      ),
                ),
              )
            else ...[
              _summaryCard(context, b!),
              if (snap!.bandixTop.isNotEmpty) _topCard(context, l10n, snap.bandixTop),
              _actionsCard(context, ref),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Map<String, dynamic> b) {
    final l10n = AppL10n.of(context);
    final online = (b['online'] as num?)?.toInt() ?? 0;
    final devices = (b['devices'] as num?)?.toInt() ?? 0;
    final wan = (b['wan'] as Map<String, dynamic>?) ?? const {};
    final conn = b['conn'] as Map<String, dynamic>?;
    final dns = b['dns'] as Map<String, dynamic>?;
    return QuartzCard(
      title: l10n.bandixTrafficTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KvRow(l10n.bandixOnlineDevices, '$online / $devices', first: true, valueMono: false),
          KvRow(l10n.bandixDownload, formatRate((wan['rx_bps'] as num?) ?? 0)),
          KvRow(l10n.bandixUpload, formatRate((wan['tx_bps'] as num?) ?? 0)),
          KvRow(
            l10n.connectionsLabel,
            conn == null ? l10n.notEnabled : '${conn['total'] ?? 0} · TCP ${conn['tcp'] ?? 0} · UDP ${conn['udp'] ?? 0}',
            valueMono: conn != null,
          ),
          KvRow(l10n.bandixDnsQueriesLabel,
              dns == null ? l10n.notEnabled : formatCount((dns['queries'] as num?) ?? 0),
              valueMono: dns != null),
          const SizedBox(height: 6),
          Text(
            l10n.bandixSummaryNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _topCard(BuildContext context, AppL10n l10n, List<Map<String, dynamic>> top) {
    final theme = Theme.of(context);
    return QuartzCard(
      title: l10n.bandixTopTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, it) in top.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (it['host'] as String?)?.isNotEmpty == true
                          ? it['host'] as String
                          : ((it['ip'] as String?)?.isNotEmpty == true
                              ? it['ip'] as String
                              : (it['mac'] as String? ?? '—')),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '↓ ${formatBytes((it['rx_b'] as num?) ?? 0)}  ↑ ${formatBytes((it['tx_b'] as num?) ?? 0)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text(
                      formatPct((it['pct'] as num?) ?? 0),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.bandixTopNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return QuartzCard(
      title: l10n.actionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionRow(context, l10n.bandixLimitTitle, () => showBandixLimitSheet(context, ref)),
          _actionRow(context, l10n.bandixWhitelistTitle, () => showBandixWhitelistSheet(context, ref)),
          _actionRow(context, l10n.bandixHostnameTitle, () => showBandixHostnameSheet(context, ref)),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text('›',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35))),
          ],
        ),
      ),
    );
  }
}
