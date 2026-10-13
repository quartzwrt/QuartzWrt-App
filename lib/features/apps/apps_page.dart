// 应用页（UI-DESIGN ⑤⑤b，定案）：双子段——「应用」控制面 +「软件包」管理面。
// 软件包面 = packages_section.dart（WP-5 `packages` 方法；旧固件未提供时降级说明卡）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'packages_section.dart';

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentBar<_Seg>(
              values: const [_Seg.apps, _Seg.packages],
              selected: _seg,
              labelOf: (s) => s == _Seg.apps ? l10n.segApps : l10n.segPackages,
              onChanged: (s) => setState(() => _seg = s),
            ),
          ),
          Expanded(
            child: _seg == _Seg.apps
                ? _AppsList(entries: entries)
                : const PackagesSection(),
          ),
        ],
      ),
    );
  }
}

class _AppsList extends StatelessWidget {
  const _AppsList({required this.entries});

  final List<(String, Map<String, dynamic>)> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
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
        // 空态才展示「未安装」说明卡（有应用在列时探针机制已自证，避免文案自相矛盾）
        if (entries.isEmpty) ...[
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
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  static String _prettyName(String id) =>
      id.isEmpty ? id : id[0].toUpperCase() + id.substring(1).replaceAll('_', ' ');
}
