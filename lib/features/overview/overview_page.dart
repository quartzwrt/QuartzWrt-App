// 概览页（UI-DESIGN ③⑨）：hero + 卡片注册表 + 四态降级。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/endpoint.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'cards.dart';
import 'registry.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final st = ref.watch(snapshotProvider);
    final router = ref.watch(activeRouterProvider);
    final snap = st.data;

    final banners = <Widget>[];
    switch (st.kind) {
      case SnapKind.needRepair:
        banners.add(
          InfoBanner(
            title: l10n.bannerNeedRepair,
            body: l10n.bannerNeedRepairBody,
            kind: DotKind.err,
          ),
        );
      case SnapKind.unavailable:
        banners.add(
          InfoBanner(
            title: st.errorCode == 'data_unavailable'
                ? l10n.bannerCollectorDown
                : l10n.bannerConnectionLost,
            body: st.errorCode == 'data_unavailable'
                ? l10n.bannerCollectorDownBody
                : l10n.bannerConnectionLostBody,
          ),
        );
      case SnapKind.degraded:
        banners.add(
          InfoBanner(
            title: l10n.bannerConnectionLost,
            body: l10n.bannerConnectionLostBody,
          ),
        );
      case SnapKind.ok:
      case SnapKind.loading:
        break;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: QzRefresh(
          onRefresh: () => ref.read(snapshotProvider.notifier).refreshNow(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ...banners,
              HeroCard(
                snapshot: snap,
                fallbackName: router?.name ?? '',
                stale: st.kind == SnapKind.degraded,
                remote:
                    ref.watch(endpointProvider)?.kind == EndpointKind.remote,
              ),
              if (st.kind == SnapKind.needRepair)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QzButton(
                    label: l10n.rePair,
                    onPressed: () => context.go('/discover'),
                    expand: true,
                  ),
                ),
              if (snap != null) ...buildOverviewCards(context, snap),
              if (snap == null && st.kind == SnapKind.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: QzSpinner(size: 22)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
