// 应用页（UI-DESIGN ⑤⑤b，定案）：双子段——「应用」控制面 +「软件包」管理面。
// 软件包面 = packages_section.dart（WP-5 `packages` 方法；旧固件未提供时降级说明卡）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../registry.dart';
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
      appBar: QzAppBar(
        titleText: l10n.appsTitle,
        trailingText: _seg == _Seg.apps ? '${entries.length}' : null,
        actions: _seg == _Seg.packages
            ? [
                QzHeaderAction(
                  label: l10n.opLogEntry,
                  onTap: () => context.push('/apps/log'),
                ),
              ]
            : const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QzTabs<_Seg>(
              values: const [_Seg.apps, _Seg.packages],
              selected: _seg,
              labelOf: (s) => s == _Seg.apps ? l10n.segApps : l10n.segPackages,
              onChanged: (s) => setState(() => _seg = s),
            ),
          ),
          Expanded(
            child: _seg == _Seg.apps
                ? _AppsList(entries: entries, snap: snap)
                : const PackagesSection(),
          ),
        ],
      ),
    );
  }
}

class _AppsList extends StatelessWidget {
  const _AppsList({required this.entries, this.snap});

  final List<(String, Map<String, dynamic>)> entries;
  final Snapshot? snap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.appsControllableIntro,
            style: QuartzType.caption.copyWith(color: t.faint),
          ),
        ),
        if (entries.isEmpty)
          QuartzCard(
            child: Text(
              l10n.appsNone,
              style: QuartzType.body.copyWith(color: t.muted),
            ),
          )
        else
          QzListGroup(
            children: [
              for (final (i, e) in entries.indexed)
                QzListRow(
                  first: i == 0,
                  leading: StatusDot(
                    e.$2['running'] == true ? DotKind.ok : DotKind.off,
                    margin: const EdgeInsets.only(right: 10),
                  ),
                  title: _prettyName(e.$1),
                  subtitle: [
                    e.$2['running'] == true ? l10n.running : l10n.stopped2,
                    if ((e.$2['core'] as String?)?.isNotEmpty == true)
                      e.$2['core'] as String,
                    ?serviceRowFor(e.$1)?.enrich?.call(l10n, e.$2, snap),
                  ].join(' · '),
                  onTap: () =>
                      context.push('/apps/detail/${Uri.encodeComponent(e.$1)}'),
                ),
            ],
          ),
        // 空态才展示「未安装」说明卡（有应用在列时探针机制已自证，避免文案自相矛盾）
        if (entries.isEmpty) ...[
          const SizedBox(height: 12),
          QuartzCard(
            title: l10n.appsNotInstalledTitle,
            child: Text(
              l10n.appsNotInstalledBody,
              style: QuartzType.sub.copyWith(color: t.muted, height: 1.55),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  static String _prettyName(String id) => id.isEmpty
      ? id
      : id[0].toUpperCase() + id.substring(1).replaceAll('_', ' ');
}
