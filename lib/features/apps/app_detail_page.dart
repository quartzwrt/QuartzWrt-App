// 应用详情（UI-DESIGN ⑪）：控制面 + 安装面汇合点。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../actions/actions.dart';

class AppDetailPage extends ConsumerWidget {
  const AppDetailPage({super.key, required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final entry = snap?.services?[appId];
    final running = entry?['running'] == true;
    final core = (entry?['core'] as String?) ?? '';
    final display = appId.isEmpty ? appId : appId[0].toUpperCase() + appId.substring(1).replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.segApps),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          QuartzCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(display, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (running ? QuartzColors.ok : Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (running ? QuartzColors.ok : Theme.of(context).colorScheme.onSurface)
                              .withValues(alpha: .35),
                        ),
                      ),
                      child: Row(
                        children: [
                          StatusDot(running ? DotKind.ok : DotKind.off),
                          Text(
                            running ? l10n.running : l10n.stopped2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: running ? QuartzColors.ok : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          QuartzCard(
            title: l10n.appDetailStatusTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KvRow(l10n.appDetailStatusRunning, running ? l10n.running : l10n.stopped2, first: true, valueMono: false),
                if (core.isNotEmpty) KvRow(l10n.coreLabel, core),
                KvRow(l10n.statusSourceLabel, l10n.statusSourceProbe, valueMono: false),
              ],
            ),
          ),
          QuartzCard(
            title: l10n.actionsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _actionRow(
                  context,
                  ref,
                  running ? l10n.actionRestart : l10n.actionStart,
                  running ? 'restart' : 'start',
                  danger: false,
                ),
                if (running)
                  _actionRow(context, ref, l10n.actionStop, 'stop', danger: true),
                const SizedBox(height: 6),
                Text(
                  l10n.actionsNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          QuartzCard(
            title: l10n.packageCardTitle,
            child: Text(
              l10n.packagesApiMissingBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context, WidgetRef ref, String label, String op, {required bool danger}) {
    return InkWell(
      onTap: () => _run(context, ref, label, op, danger: danger),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: danger ? FontWeight.w600 : FontWeight.w400,
                  color: danger ? QuartzColors.err : null,
                ),
              ),
            ),
            Text(
              '›',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, String label, String op, {required bool danger}) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    if (danger) {
      final ok = await showConfirmSheet(
        context,
        title: '$label · ${appId.isNotEmpty ? appId[0].toUpperCase() + appId.substring(1) : appId}',
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    final spec = serviceAction(op: op, label: label, name: appId);
    final r = await runAction(tm, spec);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }
}
