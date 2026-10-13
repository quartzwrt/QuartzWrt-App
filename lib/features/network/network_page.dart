// 网络页（UI-DESIGN ④）：WAN 管理 + 无线（按接口统计，契约 v1 可得）+
// 上网设备入口 + 网络服务控制（控制归口：网络控制在本页）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../actions/actions.dart';
import '../overview/cards.dart';

class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final st = ref.watch(snapshotProvider);
    final snap = st.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.networkTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          if (snap != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  l10n.clientsOnlineHeader(snap.clientsTotal),
                  style: const TextStyle(color: QuartzColors.accent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (snap == null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l10n.bannerConnectionLostBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
          if (snap != null) ...[
            networkCard(context, snap),
            _wirelessCard(context, snap),
            clientsCard(context, snap, onOpenAll: () => context.push('/network/clients')),
            _networkServicesCard(context, ref, snap),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 无线汇总：由 clients 的 iface 分组派生（契约 v1 可得；专属 wireless 节落地后
  /// 走 L2 富化替换本卡）。
  Widget _wirelessCard(BuildContext context, snap) {
    final l10n = AppL10n.of(context);
    final groups = <String, int>{};
    for (final c in snap.clientItems) {
      final iface = (c['iface'] as String?) ?? '';
      if (iface.isEmpty) continue;
      groups[iface] = (groups[iface] ?? 0) + 1;
    }
    if (groups.isEmpty) return const SizedBox.shrink();
    final rows = groups.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return QuartzCard(
      title: l10n.wirelessCardTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, e) in rows.indexed)
            KvRow(e.key, l10n.clientsOnlineHeader(e.value), first: i == 0, valueMono: false),
        ],
      ),
    );
  }

  Widget _networkServicesCard(BuildContext context, WidgetRef ref, snap) {
    final l10n = AppL10n.of(context);
    return QuartzCard(
      title: l10n.networkServicesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KvRow(
            l10n.dnsServiceLabel,
            '',
            first: true,
            valueMono: false,
            valueWidget: GestureDetector(
              onTap: () => _restartDns(context, ref, l10n),
              child: Text(
                '${l10n.actionRestart} ›',
                style: const TextStyle(color: QuartzColors.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          KvRow(
            l10n.wanReconnectPlanned,
            '',
            valueMono: false,
            valueWidget: Text(
              '›',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restartDns(BuildContext context, WidgetRef ref, AppL10n l10n) async {
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final ok = await showConfirmSheet(
      context,
      title: '${l10n.actionRestart} · ${l10n.dnsServiceLabel}',
      body: l10n.routerPasswordHint,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    final spec = serviceAction(op: 'restart', label: l10n.actionRestart, name: 'dnsmasq');
    final r = await runAction(tm, spec);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }
}
