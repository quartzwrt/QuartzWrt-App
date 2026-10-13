// 应用页（UI-DESIGN ⑤⑤b，定案）：双子段——「应用」控制面 +「软件包」管理面。
// 软件包面依赖 WP-5 `packages` 扩展（已登记）；路由器未实现时降级展示说明卡。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/envelope.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

enum _Seg { apps, packages }

class AppsPage extends ConsumerStatefulWidget {
  const AppsPage({super.key});

  @override
  ConsumerState<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends ConsumerState<AppsPage> {
  _Seg _seg = _Seg.apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final entries = snap?.serviceEntries ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appsTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          if (_seg == _Seg.packages)
            TextButton(
              onPressed: () => context.push('/apps/log'),
              child: Text(l10n.opLogEntry),
            ),
          if (_seg == _Seg.apps)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${entries.length}',
                  style: const TextStyle(color: QuartzColors.accent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SegmentBar<_Seg>(
            values: const [_Seg.apps, _Seg.packages],
            selected: _seg,
            labelOf: (s) => s == _Seg.apps ? l10n.segApps : l10n.segPackages,
            onChanged: (s) => setState(() => _seg = s),
          ),
          if (_seg == _Seg.apps) ..._appsSection(context, l10n, entries),
          if (_seg == _Seg.packages) const _PackagesSection(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _appsSection(BuildContext context, AppL10n l10n, List<(String, Map<String, dynamic>)> entries) {
    final theme = Theme.of(context);
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          l10n.appsControllableIntro,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .5),
          ),
        ),
      ),
      if (entries.isEmpty)
        QuartzCard(child: Text(l10n.appsNone))
      else
        QuartzCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, e) in entries.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(_prettyName(e.$1), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      StatusDot(e.$2['running'] == true ? DotKind.ok : DotKind.off),
                      Expanded(
                        child: Text(
                          [
                            e.$2['running'] == true ? l10n.running : l10n.stopped2,
                            if ((e.$2['core'] as String?)?.isNotEmpty == true) e.$2['core'] as String,
                          ].join(' · '),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => context.push('/apps/detail/${Uri.encodeComponent(e.$1)}'),
                ),
              ],
            ],
          ),
        ),
      const SizedBox(height: 12),
      QuartzCard(
        title: l10n.appsNotInstalledTitle,
        child: Text(
          l10n.appsNotInstalledBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .55),
            height: 1.5,
          ),
        ),
      ),
    ];
  }

  static String _prettyName(String id) =>
      id.isEmpty ? id : id[0].toUpperCase() + id.substring(1).replaceAll('_', ' ');
}

/// 软件包管理面（skeleton；数据面待 WP-5 `packages` 扩展）。
class _PackagesSection extends ConsumerStatefulWidget {
  const _PackagesSection();

  @override
  ConsumerState<_PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends ConsumerState<_PackagesSection> {
  Future<ApiResult>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final tm = ref.read(tokenManagerProvider);
    setState(() {
      _future = tm == null
          ? Future.value(ApiResult.fail(0, const ApiError('no_router', '')))
          : tm.call('packages', {'scope': 'installed'});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<ApiResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final r = snap.data;
        final available = r?.ok == true;
        if (!available) {
          return Column(
            children: [
              QuartzCard(
                title: l10n.packagesApiMissingTitle,
                child: Text(
                  l10n.packagesApiMissingBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .55),
                    height: 1.5,
                  ),
                ),
              ),
              QuartzCard(
                title: l10n.installNewTitle,
                child: Text(
                  l10n.installNewBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .55),
                    height: 1.5,
                  ),
                ),
              ),
              OutlinedButton(onPressed: _load, child: Text(l10n.refresh)),
            ],
          );
        }
        // API 可用（未来）：防御性渲染——条目键名宽松解析。
        final list = (r!.data['packages'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
            const <Map<String, dynamic>>[];
        final upgradable = list.where((p) => (p['upgradable_to'] as String?)?.isNotEmpty == true).toList();
        return Column(
          children: [
            if (upgradable.isNotEmpty)
              QuartzCard(
                title: l10n.upgradableHeader(upgradable.length),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, p) in upgradable.indexed)
                      KvRow(
                        (p['name'] as String?) ?? '',
                        '${p['version'] ?? ''} → ${p['upgradable_to'] ?? ''}',
                        first: i == 0,
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _upgradeAll,
                      child: Text(l10n.upgradeAllBtn(upgradable.length)),
                    ),
                  ],
                ),
              ),
            QuartzCard(
              title: l10n.installedHeader(list.length),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, p) in list.take(6).indexed)
                    KvRow(
                      (p['name'] as String?) ?? '',
                      [
                        (p['version'] as String?) ?? '',
                        if ((p['size'] as String?)?.isNotEmpty == true) p['size'] as String,
                      ].join(' · '),
                      first: i == 0,
                    ),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.installNewTitle,
              child: Text(
                l10n.installNewBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .55),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _upgradeAll() async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.upgradeAllBtn(0).replaceAll(' (0)', ''),
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    final r = await tm.call('action', {'action': 'packages.upgrade', 'args': const <String, dynamic>{}});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          r.ok ? l10n.actionDone : l10n.actionFailed(r.error?.detail ?? r.error?.message ?? ''),
        ),
      ),
    );
    _load();
  }
}
