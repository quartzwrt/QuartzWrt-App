// 应用详情（UI-DESIGN ⑪）：控制面 + 安装面汇合点。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/packages.dart';
import '../../core/theme.dart';
import '../../format.dart';
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
            child: _PackageCard(appId: appId),
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

/// 详情页「软件包」卡（⑪ 控制面+安装面汇合）：按应用 id 反向查已安装软件包；
/// 有升级时提供单包升级入口（卸载/浏览统一在「软件包」子段，避免详情页危险面）。
class _PackageCard extends ConsumerStatefulWidget {
  const _PackageCard({required this.appId});

  final String appId;

  @override
  ConsumerState<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends ConsumerState<_PackageCard> {
  bool _loading = true;
  bool _apiMissing = false;
  PackageItem? _pkg;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tm = ref.read(tokenManagerProvider);
    if (tm == null || widget.appId.isEmpty) {
      setState(() {
        _loading = false;
        _apiMissing = true;
      });
      return;
    }
    setState(() => _loading = true);
    final r = await tm.call('packages', {'scope': 'installed', 'query': widget.appId, 'per_page': 100});
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _apiMissing = false;
        final items = PackagesPage.fromPayload(r.data).items;
        // 名称精确匹配优先，否则取包含关系的第一项（如 openclash → luci-app-openclash）
        _pkg = items.where((p) => p.name == widget.appId).firstOrNull ??
            items.where((p) => p.name.contains(widget.appId)).firstOrNull;
      } else if (r.error?.code == 'bad_request') {
        _apiMissing = true;
      }
    });
  }

  Future<void> _upgrade(PackageItem p) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null || _acting) return;
    setState(() => _acting = true);
    final r = await tm.call('action', {
      'action': 'packages.upgrade',
      'args': {'name': p.name},
    });
    if (!mounted) return;
    setState(() => _acting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.pkgUpgraded(p.name) : l10n.actionFailed((r.error?.detail ?? r.error?.message) ?? ''))),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: .5),
      height: 1.5,
    );
    if (_loading) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()));
    if (_apiMissing) return Text(l10n.packagesApiMissingBody, style: small);
    final p = _pkg;
    if (p == null) return Text(l10n.pkgCardNotInstalled, style: small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KvRow(l10n.pkgCardName, p.name, first: true),
        KvRow(l10n.packageVersion, p.version),
        if (p.installedSize > 0) KvRow(l10n.packageSize, formatBytes(p.installedSize)),
        if (p.upgradable) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pkgCardUpgradeTo(p.targetVersion),
                  style: theme.textTheme.bodySmall?.copyWith(color: QuartzColors.warn, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.tonal(
                onPressed: _acting ? null : () => _upgrade(p),
                child: Text(l10n.pkgUpgrade),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
