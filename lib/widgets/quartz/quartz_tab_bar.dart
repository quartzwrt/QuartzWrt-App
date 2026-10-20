// 底部导航：Dashboard 风格平底 chrome（1px 上描边 + accent 选中），不再用悬浮胶囊。
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'quartz_controls.dart';
import 'quartz_icons.dart';

class QzTabItem {
  const QzTabItem({required this.icon, required this.label});

  final String icon;
  final String label;
}

class QzTabBar extends StatelessWidget {
  const QzTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<QzTabItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final chrome = t.chrome.withValues(
      alpha: (t.panelAlpha * (t.isDark ? .80 : .72)).clamp(0, 1),
    );
    Widget bar = Container(
      color: chrome,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: QuartzSizes.tabBar,
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
                  child: QzPressable(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.zero,
                    selected: i == index,
                    semanticLabel: item.label,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QzIcon(
                          item.icon,
                          size: 21,
                          color: i == index ? t.accent : t.faint,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: QuartzType.tiny.copyWith(
                            fontSize: 10.5,
                            color: i == index ? t.accent : t.faint,
                            fontWeight: FontWeight.w600,
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
    if (t.blurSigma > 0) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: bar,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: bar,
    );
  }
}

/// 兼容旧 shell 的图标常量集中处（避免页面再引用 Material Icons）。
abstract final class QzNavIcons {
  static const overview = QzIcons.navOverview;
  static const router = QzIcons.navRouter;
  static const apps = QzIcons.navApps;
  static const cellular = QzIcons.navCellular;
  static const settings = QzIcons.navSettings;
}
