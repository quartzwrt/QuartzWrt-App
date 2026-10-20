// Quartz 页面骨架与列表行。
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'quartz_controls.dart';
import 'quartz_icons.dart';

/// Dashboard 卡面材质：panel 色 + 1px 描边 + 圆角；面板不透明度 <100% 时
/// 自动挂背景模糊（对应网页端 panel_opacity / blur）。
class QzPanel extends StatelessWidget {
  const QzPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderRadius,
    this.border,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final radius = borderRadius ?? BorderRadius.circular(QuartzRadii.md);
    final alpha = t.panelAlpha.clamp(.5, 1.0);
    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? t.panel).withValues(alpha: alpha),
        borderRadius: radius,
        border: border ?? Border.all(color: t.border),
      ),
      child: child,
    );
    if (blur && alpha < .999 && t.blurSigma > 0) {
      panel = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: panel,
        ),
      );
    }
    return Padding(padding: margin, child: panel);
  }
}

/// 设计稿顶栏：padding 6/18/10、标题 22/700、右侧 accent 文本。
/// 仍放在 Scaffold.appBar 槽位，但不再使用 Material AppBar。
class QzAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QzAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions = const [],
    this.trailingText,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = QuartzSizes.header,
  });

  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget> actions;
  final String? trailingText;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final canPop = Navigator.of(context).canPop();
    final lead =
        leading ??
        (automaticallyImplyLeading && canPop
            ? QzIconButton(
                icon: QzIcons.chevronLeft,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: () => Navigator.maybePop(context),
              )
            : null);
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: toolbarHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
            child: Row(
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 2)],
                Expanded(
                  child: DefaultTextStyle(
                    style: QuartzType.screenTitle.copyWith(color: t.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title ?? Text(titleText ?? ''),
                  ),
                ),
                if (trailingText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      trailingText!,
                      style: QuartzType.subStrong.copyWith(
                        color: t.accent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 可点击的顶栏动作（设计稿右侧 accent 文本）。
class QzHeaderAction extends StatelessWidget {
  const QzHeaderAction({
    super.key,
    required this.label,
    this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return QzPressable(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(QuartzRadii.sm),
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          label,
          style: QuartzType.subStrong.copyWith(
            color: color ?? t.accent,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 简单页面壳：统一 QzAppBar + Scaffold 背景。
class QzScreen extends StatelessWidget {
  const QzScreen({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions = const [],
    this.trailingText,
    this.automaticallyImplyLeading = true,
    required this.child,
  });

  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget> actions;
  final String? trailingText;
  final bool automaticallyImplyLeading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QzAppBar(
        title: title,
        titleText: titleText,
        leading: leading,
        actions: actions,
        trailingText: trailingText,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: child,
    );
  }
}

/// 设计稿列表行：34/32 中性图标块 + 14/600 标题 + 12 muted 副标题 + chip + ›。
class QzListRow extends StatelessWidget {
  const QzListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.chip,
    this.chipKind = QzChipKind.native,
    this.onTap,
    this.showChevron = true,
    this.first = false,
    this.compact = false,
    this.danger = false,
    this.iconColor,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? icon;
  final Widget? leading;
  final Widget? trailing;
  final String? chip;
  final QzChipKind chipKind;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool first;
  final bool compact;
  final bool danger;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final titleColor = danger ? t.err : t.text;
    final lead =
        leading ??
        (icon == null
            ? null
            : Container(
                width: compact
                    ? QuartzSizes.iconTileCompact
                    : QuartzSizes.iconTile,
                height: compact
                    ? QuartzSizes.iconTileCompact
                    : QuartzSizes.iconTile,
                decoration: BoxDecoration(
                  color: t.well,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: QzIcon(
                    icon!,
                    size: compact ? 17 : 18,
                    color: iconColor ?? t.muted,
                  ),
                ),
              ));
    return QzPressable(
      onTap: onTap,
      enabled: onTap != null,
      highlight: true,
      semanticLabel: title,
      child: Container(
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 6.5 : 11),
        decoration: first
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: t.border)),
              ),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QuartzType.bodyStrong.copyWith(color: titleColor),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QuartzType.caption.copyWith(
                        color: t.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (chip != null) ...[
              const SizedBox(width: 8),
              QzChip(chip!, kind: chipKind),
            ],
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            if (showChevron) ...[
              const SizedBox(width: 4),
              QzIcon(QzIcons.chevronRight, size: 16, color: t.faint),
            ],
          ],
        ),
      ),
    );
  }
}

/// 一组行（单张卡片 + 行间 1px 分隔线）。
class QzListGroup extends StatelessWidget {
  const QzListGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return QzPanel(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QuartzRadii.md - 1),
        child: Column(children: children),
      ),
    );
  }
}

class QzSectionLabel extends StatelessWidget {
  const QzSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(text, style: QuartzType.label.copyWith(color: t.faint)),
    );
  }
}

/// 通用空态/说明块。
class QzEmpty extends StatelessWidget {
  const QzEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: QuartzType.sub.copyWith(color: t.faint),
      ),
    );
  }
}
