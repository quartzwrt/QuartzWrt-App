// 应用外壳：底部四 tab（概览/网络/应用/设置）+ 预留第 5 位（当前隐藏）。
//
// W6.6：由 StatefulShellRoute.indexedStack 驱动——切 tab 不重建整页
// （各 tab 的滚动位置与页面状态保留）。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tabs = <(IconData, String)>[
      (Icons.monitor_heart_outlined, l10n.navOverview),
      (Icons.public_outlined, l10n.navNetwork),
      (Icons.grid_view_outlined, l10n.navApps),
      (Icons.settings_outlined, l10n.navSettings),
      // 第 5 tab 位预留（设计与架构定案）：未来功能上线时在此追加并过评审。
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _QuartzTabBar(
        tabs: tabs,
        index: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
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
