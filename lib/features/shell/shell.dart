// 应用外壳：底部 tab（概览 / 路由器 / 应用 / 蜂窝 / 设置）。
//
// 「蜂窝」为**条件 tab**（IA v2 定案 D10′）：`snapshot.cellular.available` 为真，
// 或该路由器**曾**确认过 qmodem+模组（粘性标记 `PairedRouter.cellularSeen`，避免
// 临时断网/采集降级导致 tab 忽隐忽现）。
//
// W6.6：由 StatefulShellRoute.indexedStack 驱动——切 tab 不重建整页
// （各 tab 的滚动位置与页面状态保留）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

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
    final branches = <(int, IconData, String)>[
      (0, Icons.monitor_heart_outlined, l10n.navOverview),
      (1, Icons.public_outlined, l10n.navRouter),
      (2, Icons.grid_view_outlined, l10n.navApps),
      if (cellularVisible) (3, Icons.cell_tower_outlined, l10n.navCellular),
      (4, Icons.settings_outlined, l10n.navSettings),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _QuartzTabBar(
        tabs: [for (final b in branches) (b.$2, b.$3)],
        index: branches.indexWhere((b) => b.$1 == navigationShell.currentIndex).clamp(0, branches.length - 1),
        onTap: (i) {
          final target = branches[i].$1;
          navigationShell.goBranch(target, initialLocation: target == navigationShell.currentIndex);
        },
      ),
    );
  }
}

class _QuartzTabBar extends StatelessWidget {
  const _QuartzTabBar({required this.tabs, required this.index, required this.onTap});

  final List<(IconData, String)> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = dark ? const Color(0x17FFFFFF) : const Color(0x14000000);
    final inactive = theme.colorScheme.onSurface.withValues(alpha: .45);
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xE61C1C1E) : const Color(0xE6F2F2F7),
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final (i, tab) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.$1,
                            size: 23,
                            color: i == index ? QuartzColors.accent : inactive,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.$2,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: i == index ? QuartzColors.accent : inactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
