// 应用外壳：底部悬浮胶囊 tab（概览 / 路由器 / 应用 / 蜂窝 / 设置）。
//
// 「蜂窝」为条件 tab（IA v2 定案 D10′）：快照显示或该路由器曾确认过
// qmodem+模组（粘性 cellularSeen）时显示。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data;
    final router = ref.watch(activeRouterProvider);
    final cellularVisible =
        (snap?.cellular?.shown ?? false) || (router?.cellularSeen ?? false);
    // index → 分支位（蜂窝隐藏时索引表整体前移/后移，保证点击落到正确分支）
    final branches = <(int, String, String)>[
      (0, QzNavIcons.overview, l10n.navOverview),
      (1, QzNavIcons.router, l10n.navRouter),
      (2, QzNavIcons.apps, l10n.navApps),
      if (cellularVisible) (3, QzNavIcons.cellular, l10n.navCellular),
      (4, QzNavIcons.settings, l10n.navSettings),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: QzTabBar(
        items: [for (final b in branches) QzTabItem(icon: b.$2, label: b.$3)],
        index: branches
            .indexWhere((b) => b.$1 == navigationShell.currentIndex)
            .clamp(0, branches.length - 1),
        onTap: (i) {
          final target = branches[i].$1;
          navigationShell.goBranch(
            target,
            initialLocation: target == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
