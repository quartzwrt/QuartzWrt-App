// 应用外壳：底部四 tab（概览/网络/应用/设置）+ 预留第 5 位（当前隐藏）。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tabs = <(String, IconData, String)>[
      ('/overview', Icons.monitor_heart_outlined, l10n.navOverview),
      ('/network', Icons.public_outlined, l10n.navNetwork),
      ('/apps', Icons.grid_view_outlined, l10n.navApps),
      ('/settings', Icons.settings_outlined, l10n.navSettings),
      // 第 5 tab 位预留（设计与架构定案）：未来功能上线时在此追加并过评审。
    ];
    return Scaffold(
      body: child,
      bottomNavigationBar: _QuartzTabBar(
        tabs: tabs,
        location: location,
        onTap: (path) => context.go(path),
      ),
    );
  }
}

class _QuartzTabBar extends StatelessWidget {
  const _QuartzTabBar({required this.tabs, required this.location, required this.onTap});

  final List<(String, IconData, String)> tabs;
  final String location;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = dark ? const Color(0x17FFFFFF) : const Color(0x14000000);
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
              for (final (path, icon, label) in tabs)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 23,
                          color: location.startsWith(path)
                              ? QuartzColors.accent
                              : theme.colorScheme.onSurface.withValues(alpha: .35),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: location.startsWith(path)
                                ? QuartzColors.accent
                                : theme.colorScheme.onSurface.withValues(alpha: .35),
                          ),
                        ),
                      ],
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
