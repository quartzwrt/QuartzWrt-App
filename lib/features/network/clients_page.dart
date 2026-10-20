// 全部上网设备（契约 ≤32 条全量）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final items = snap?.clientItems ?? const [];
    return Scaffold(
      appBar: QzAppBar(title: Text(l10n.clientsPageTitle)),
      body: items.isEmpty
          ? Center(child: Text(l10n.clientsEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                final (unit, n) = relativeTime((c['last_seen'] as int?) ?? 0);
                final seen = switch (unit) {
                  'now' => l10n.lastSeenNow,
                  'min' => l10n.lastSeenMin(n),
                  'hour' => l10n.lastSeenHour(n),
                  _ => l10n.lastSeenDay(n),
                };
                return QuartzCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      const QzIcon(QzIcons.clients, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c['host'] as String?)?.isNotEmpty == true
                                  ? c['host'] as String
                                  : ((c['mac'] as String?) ?? ''),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(c['ip'] as String?) ?? ''} · ${(c['mac'] as String?) ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: .55),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            seen,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            (c['iface'] as String?) ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: .45),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
