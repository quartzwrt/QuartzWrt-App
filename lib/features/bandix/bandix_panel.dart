// bandix 详情扩展卡（WP-6 L2 富化行；UI-DESIGN §4.2 ServiceRowSpec.detailCard）。
//
// 数据面 = daemon 快照 `snapshot.bandix`（契约 §3.7，与 Dashboard 同字节，
// 5s 轮询自动刷新）；动作面 = WP-5「ubus 转发项」（bandix.*）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'bandix_format.dart';
import 'bandix_sheets.dart';

class BandixPanel extends ConsumerWidget {
  const BandixPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final b = snap?.bandix;
    final available = snap?.bandixAvailable == true;

    if (!available) {
      return QuartzCard(
        title: l10n.bandixTitle,
        child: Text(
          b == null ? l10n.bandixUnavailable : l10n.bandixNotEnabled,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .6),
            height: 1.5,
          ),
        ),
      );
    }

    final online = (b!['online'] as num?)?.toInt() ?? 0;
    final devices = (b['devices'] as num?)?.toInt() ?? 0;
    final lim = b['limits'] as Map<String, dynamic>?;
    final conn = b['conn'] as Map<String, dynamic>?;
    final dns = b['dns'] as Map<String, dynamic>?;

    return QuartzCard(
      title: l10n.bandixTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KvRow(
            l10n.bandixOnlineDevices,
            '$online / $devices',
            first: true,
            valueMono: false,
          ),
          // 总体限速策略（2026-10-17 用户指令：替代原 WAN 速率行——与网络卡重复）
          if (lim != null) ...[
            KvRow(
              l10n.bandixDefaultLimitLabel,
              bandixDefaultLimitText(l10n, lim),
            ),
            KvRow(
              l10n.bandixWhitelistState,
              bandixPolicyCountsText(l10n, lim),
              valueMono: false,
            ),
          ],
          KvRow(
            l10n.connectionsLabel,
            conn == null
                ? l10n.notEnabled
                : '${conn['total'] ?? 0} · TCP ${conn['tcp'] ?? 0} · UDP ${conn['udp'] ?? 0}',
            valueMono: conn != null,
          ),
          KvRow(
            l10n.bandixDnsQueriesLabel,
            dns == null
                ? l10n.notEnabled
                : formatCount((dns['queries'] as num?) ?? 0),
            valueMono: dns != null,
          ),
          const SizedBox(height: 10),
          _row(
            context,
            l10n.bandixTrafficTitle,
            () => context.push('/apps/bandix'),
          ),
          _row(
            context,
            l10n.bandixLimitTitle,
            () => showBandixLimitSheet(context, ref),
          ),
          _row(
            context,
            l10n.bandixWhitelistTitle,
            () => showBandixWhitelistSheet(context, ref),
          ),
          _row(
            context,
            l10n.bandixHostnameTitle,
            () => showBandixHostnameSheet(context, ref),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.bandixPanelNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, VoidCallback onTap) {
    return QzPressable(
      highlight: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '›',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
