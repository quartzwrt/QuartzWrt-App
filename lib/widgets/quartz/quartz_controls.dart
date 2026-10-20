// Quartz UI kit：按钮、开关、输入框、选择行、分段控件、chip、进度条、加载。
// 纪律：这里不出现 Material 可见组件；全部按 design/ia-v2-preview.html 规格绘制。
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import 'quartz_icons.dart';

/// 按下态：不用 ripple，只做轻微透明度变化。
class QzPressable extends StatefulWidget {
  const QzPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.borderRadius,
    this.highlight = false,
    this.semanticLabel,
    this.selected,
    this.button = true,
    this.scaleOnPress = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final BorderRadius? borderRadius;
  final bool highlight;
  final String? semanticLabel;
  final bool? selected;
  final bool button;
  final bool scaleOnPress;

  @override
  State<QzPressable> createState() => _QzPressableState();
}

class _QzPressableState extends State<QzPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (!mounted || !widget.enabled || widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(QuartzRadii.sm);
    final pressed = AnimatedOpacity(
      opacity: _pressed ? .62 : 1,
      duration: QuartzMotion.fast,
      child: AnimatedContainer(
        duration: QuartzMotion.fast,
        decoration: widget.highlight
            ? BoxDecoration(
                color: _pressed ? t.hover : Colors.transparent,
                borderRadius: radius,
              )
            : null,
        child: widget.child,
      ),
    );
    final content = widget.scaleOnPress
        ? AnimatedScale(
            scale: _pressed ? .975 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: pressed,
          )
        : pressed;
    return Semantics(
      button: widget.button,
      enabled: widget.enabled && widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: content,
      ),
    );
  }
}

enum QzButtonKind { primary, plain, danger, ghost }

enum QzButtonSize { normal, small }

class QzButton extends StatelessWidget {
  const QzButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = QzButtonKind.primary,
    this.size = QzButtonSize.normal,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final QzButtonKind kind;
  final QzButtonSize size;
  final String? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final (bg, fg, border) = switch (kind) {
      QzButtonKind.primary => (t.accent, Colors.white, null),
      QzButtonKind.plain => (t.raised, t.text, t.borderStrong),
      QzButtonKind.danger => (Colors.transparent, t.err, t.borderStrong),
      QzButtonKind.ghost => (Colors.transparent, t.accent, null),
    };
    final h = size == QzButtonSize.normal ? QuartzSizes.button : 34.0;
    final style = size == QzButtonSize.normal
        ? QuartzType.button
        : QuartzType.buttonSmall;
    final radius = BorderRadius.circular(
      size == QzButtonSize.normal ? QuartzRadii.button : 9,
    );
    final enabled = onPressed != null;
    final child = AnimatedOpacity(
      opacity: enabled ? 1 : .4,
      duration: QuartzMotion.fast,
      child: Container(
        height: h,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: size == QzButtonSize.normal ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              QzIcon(
                icon!,
                size: size == QzButtonSize.normal ? 18 : 16,
                color: fg,
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: style.copyWith(color: fg)),
          ],
        ),
      ),
    );
    return QzPressable(
      onTap: enabled ? onPressed : null,
      enabled: enabled,
      borderRadius: radius,
      semanticLabel: label,
      scaleOnPress: true,
      child: child,
    );
  }
}

class QzIconButton extends StatelessWidget {
  const QzIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.color,
    this.size = 18,
  });

  final String icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: QuartzSizes.tap,
      height: QuartzSizes.tap,
      child: Center(
        child: QzIcon(icon, size: size, color: color),
      ),
    );
    final button = QzPressable(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(QuartzRadii.sm),
      highlight: true,
      semanticLabel: tooltip,
      scaleOnPress: true,
      child: child,
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 输入框内的小图标（眼睛、清除等），32×32 命中区。
class QzInlineIconButton extends StatelessWidget {
  const QzInlineIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.color,
    this.size = 19,
  });

  final String icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QzPressable(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(QuartzRadii.sm),
      semanticLabel: tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: QzIcon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

/// 44×26 胶囊开关；关闭时 well 底 + 强描边，开启时 ok 绿底。
class QzToggle extends StatelessWidget {
  const QzToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final enabled = onChanged != null;
    final track = AnimatedContainer(
      duration: QuartzMotion.normal,
      width: QuartzSizes.toggleW,
      height: QuartzSizes.toggleH,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? t.accent : t.well,
        borderRadius: BorderRadius.circular(QuartzRadii.pill),
        border: Border.all(color: value ? Colors.transparent : t.borderStrong),
      ),
      child: AnimatedAlign(
        duration: QuartzMotion.normal,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: QuartzSizes.toggleKnob,
          height: QuartzSizes.toggleKnob,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [QuartzEffects.knobShadow],
          ),
        ),
      ),
    );
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .4,
        duration: QuartzMotion.fast,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: SizedBox(
            width: QuartzSizes.tap,
            height: QuartzSizes.tap,
            child: Center(child: track),
          ),
        ),
      ),
    );
  }
}

enum QzChipKind { native, generic, muted, warn, danger }

class QzChip extends StatelessWidget {
  const QzChip(this.label, {super.key, this.kind = QzChipKind.native});

  final String label;
  final QzChipKind kind;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final (fg, border) = switch (kind) {
      QzChipKind.native => (t.ok, t.ok.withValues(alpha: .35)),
      QzChipKind.generic => (t.accent, t.accent.withValues(alpha: .35)),
      QzChipKind.muted => (t.faint, t.borderStrong),
      QzChipKind.warn => (t.warn, t.warn.withValues(alpha: .35)),
      QzChipKind.danger => (t.err, t.err.withValues(alpha: .35)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: kind == QzChipKind.muted
            ? Colors.transparent
            : fg.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(QuartzRadii.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: QuartzType.tiny.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 可选 chip（单选）：用于少量枚举值，视觉与 QzChip 同族。
class QzChoiceChip extends StatelessWidget {
  const QzChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final enabled = onTap != null;
    return QzPressable(
      onTap: onTap,
      enabled: enabled,
      selected: selected,
      borderRadius: BorderRadius.circular(8),
      semanticLabel: label,
      child: AnimatedContainer(
        duration: QuartzMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.accent.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? t.accent : t.borderStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? t.accent : (enabled ? t.text : t.faint),
          ),
        ),
      ),
    );
  }
}

class QzField extends StatefulWidget {
  const QzField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.prefix,
    this.autofocus = false,
    this.monospace = false,
    this.textAlign = TextAlign.start,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Widget? prefix;
  final bool autofocus;
  final bool monospace;
  final TextAlign textAlign;
  final FocusNode? focusNode;

  @override
  State<QzField> createState() => _QzFieldState();
}

class _QzFieldState extends State<QzField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final valueStyle = widget.monospace
        ? QuartzType.caption.copyWith(
            color: t.text,
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.6,
          )
        : QuartzType.body.copyWith(color: t.text);
    final field = CupertinoTextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscure,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      textAlign: widget.textAlign,
      style: valueStyle,
      cursorColor: t.accent,
      padding: EdgeInsets.zero,
      // 外框由 QzField 自己绘制；CupertinoTextField 默认会画白底圆角框。
      decoration: null,
      placeholder: widget.hint,
      placeholderStyle: QuartzType.body.copyWith(color: t.faint),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: QuartzType.caption.copyWith(color: t.text),
          ),
          const SizedBox(height: 5),
        ],
        AnimatedContainer(
          duration: QuartzMotion.fast,
          padding: EdgeInsets.fromLTRB(
            10,
            widget.monospace ? 8 : 9,
            8,
            widget.monospace ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: t.well,
            borderRadius: BorderRadius.circular(QuartzRadii.field),
            border: Border.all(color: _focused ? t.accent : t.border),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: t.accent.withValues(alpha: .18),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: 8),
              ],
              Expanded(child: field),
              if (widget.suffix != null) ...[
                const SizedBox(width: 4),
                widget.suffix!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class QzSelectRow extends StatelessWidget {
  const QzSelectRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.placeholder,
    this.enabled = true,
    this.first = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final String? placeholder;
  final bool enabled;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final v = (value == null || value!.isEmpty) ? (placeholder ?? '—') : value!;
    return QzPressable(
      onTap: enabled ? onTap : null,
      enabled: enabled,
      highlight: true,
      borderRadius: BorderRadius.circular(QuartzRadii.sm),
      semanticLabel: '$label: $v',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: first
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: t.border)),
              ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: QuartzType.body.copyWith(color: t.text),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                v,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: QuartzType.bodyStrong.copyWith(
                  color: enabled ? t.text : t.faint,
                ),
              ),
            ),
            const SizedBox(width: 6),
            QzIcon(QzIcons.chevronDown, size: 16, color: t.faint),
          ],
        ),
      ),
    );
  }
}

class QzSegmented<T> extends StatelessWidget {
  const QzSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.margin = EdgeInsets.zero,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: t.segTrack,
          borderRadius: BorderRadius.circular(QuartzRadii.sm + 1),
        ),
        child: Row(
          children: [
            for (final (i, v) in values.indexed) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: QzPressable(
                  onTap: () => onChanged(v),
                  borderRadius: BorderRadius.circular(7),
                  selected: v == selected,
                  child: AnimatedContainer(
                    duration: QuartzMotion.fast,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: v == selected
                        ? BoxDecoration(
                            color: t.raised,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: const [QuartzEffects.segShadow],
                          )
                        : null,
                    child: Text(
                      labelOf(v),
                      textAlign: TextAlign.center,
                      style: QuartzType.sub.copyWith(
                        color: v == selected ? t.text : t.muted,
                        fontWeight: v == selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 5px 轨道 + 18px 白色旋钮；拖动 1:1 跟手，无 Material Slider。
class QzSlider extends StatelessWidget {
  const QzSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final p = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Semantics(
      slider: true,
      value: value.round().toString(),
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          void update(double dx) {
            final f = (dx / width).clamp(0.0, 1.0);
            onChanged(min + f * (max - min));
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragStart: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: SizedBox(
              height: 30,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: t.well,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: t.border),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: p,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width - 18) * p,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33000000)),
                        boxShadow: const [QuartzEffects.knobShadow],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class QzBar extends StatelessWidget {
  const QzBar({super.key, required this.pct, this.color, this.height = 6});

  final double pct;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final p = (pct.isFinite ? pct : 0).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: p),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: t.barTrack)),
                SizedBox(
                  width: c.maxWidth * v,
                  height: height,
                  child: ColoredBox(color: color ?? t.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QzSpinner extends StatefulWidget {
  const QzSpinner({super.key, this.size = 18, this.stroke = 2, this.color});

  final double size;
  final double stroke;
  final Color? color;

  @override
  State<QzSpinner> createState() => _QzSpinnerState();
}

class _QzSpinnerState extends State<QzSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          turns: _c,
          child: CustomPaint(
            painter: _SpinnerPainter(
              color: widget.color ?? t.accent,
              stroke: widget.stroke,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: r),
      -math.pi / 2,
      math.pi * 1.25,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) =>
      old.color != color || old.stroke != stroke;
}

/// 迁移用桥：接受 Material IconButton 的常见参数，但渲染成 QzIconButton（SVG、无 ripple）。
/// 新代码请直接用 QzIconButton。
class QzLegacyIconButton extends StatelessWidget {
  const QzLegacyIconButton({
    super.key,
    this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.iconSize,
    this.padding,
    this.constraints,
    this.style,
    this.splashRadius,
    this.isSelected,
    this.selectedIcon,
    this.enableFeedback,
    this.visualDensity,
    this.focusNode,
    this.autofocus,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
  });

  final Widget? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final ButtonStyle? style;
  final double? splashRadius;
  final bool? isSelected;
  final Widget? selectedIcon;
  final bool? enableFeedback;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final bool? autofocus;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;

  @override
  Widget build(BuildContext context) {
    final data = icon is Icon ? (icon! as Icon).icon : null;
    return QzIconButton(
      icon: qzAssetForMaterialIcon(data),
      tooltip: tooltip,
      onTap: onPressed,
      color: color,
      size: iconSize ?? 18,
    );
  }
}

String qzAssetForMaterialIcon(IconData? icon) {
  if (icon == Icons.chevron_left ||
      icon == Icons.arrow_back ||
      icon == Icons.arrow_back_ios) {
    return QzIcons.chevronLeft;
  }
  if (icon == Icons.chevron_right ||
      icon == Icons.arrow_forward ||
      icon == Icons.arrow_forward_ios) {
    return QzIcons.chevronRight;
  }
  if (icon == Icons.expand_more) return QzIcons.chevronDown;
  if (icon == Icons.refresh || icon == Icons.autorenew) return QzIcons.refresh;
  if (icon == Icons.add) return QzIcons.add;
  if (icon == Icons.close) return QzIcons.close;
  if (icon == Icons.check) return QzIcons.check;
  if (icon == Icons.edit || icon == Icons.edit_outlined) return QzIcons.edit;
  if (icon == Icons.delete || icon == Icons.delete_outline) {
    return QzIcons.delete;
  }
  if (icon == Icons.more_horiz || icon == Icons.more_vert) return QzIcons.more;
  if (icon == Icons.search) return QzIcons.search;
  if (icon == Icons.visibility || icon == Icons.visibility_outlined) {
    return QzIcons.eye;
  }
  if (icon == Icons.visibility_off || icon == Icons.visibility_off_outlined) {
    return QzIcons.eyeOff;
  }
  if (icon == Icons.error_outline || icon == Icons.warning_amber_outlined) {
    return QzIcons.warning;
  }
  if (icon == Icons.info_outline || icon == Icons.info) return QzIcons.info;
  if (icon == Icons.cloud_outlined || icon == Icons.cloud) return QzIcons.cloud;
  if (icon == Icons.sync) return QzIcons.sync;
  if (icon == Icons.router_outlined) return QzIcons.routerAntenna;
  if (icon == Icons.shield_outlined || icon == Icons.shield) {
    return QzIcons.shield;
  }
  if (icon == Icons.wifi || icon == Icons.wifi_outlined) return QzIcons.wifi;
  if (icon == Icons.lan_outlined) return QzIcons.interfaces;
  if (icon == Icons.dns_outlined) return QzIcons.dhcp;
  if (icon == Icons.alt_route_outlined) return QzIcons.route;
  if (icon == Icons.settings_suggest_outlined) return QzIcons.system;
  if (icon == Icons.admin_panel_settings_outlined) return QzIcons.admin;
  if (icon == Icons.play_circle_outline || icon == Icons.play_arrow) {
    return QzIcons.play;
  }
  if (icon == Icons.storage_outlined || icon == Icons.storage) {
    return QzIcons.memory;
  }
  if (icon == Icons.schedule_outlined || icon == Icons.schedule) {
    return QzIcons.clock;
  }
  if (icon == Icons.lightbulb_outline || icon == Icons.lightbulb_outlined) {
    return QzIcons.advanced;
  }
  if (icon == Icons.devices_outlined || icon == Icons.devices) {
    return QzIcons.clients;
  }
  if (icon == Icons.article_outlined || icon == Icons.article) {
    return QzIcons.list;
  }
  if (icon == Icons.terminal) return QzIcons.terminal;
  if (icon == Icons.tune) return QzIcons.tune;
  if (icon == Icons.sms_outlined || icon == Icons.sms) return QzIcons.sms;
  if (icon == Icons.sim_card_outlined || icon == Icons.sim_card) {
    return QzIcons.sim;
  }
  if (icon == Icons.wifi_tethering) return QzIcons.networkConfig;
  if (icon == Icons.download) return QzIcons.download;
  if (icon == Icons.upload) return QzIcons.upload;
  if (icon == Icons.power_settings_new) return QzIcons.power;
  if (icon == Icons.restart_alt) return QzIcons.restart;
  if (icon == Icons.pause) return QzIcons.pause;
  return QzIcons.more;
}

/// 迁移用桥：接受 Material 按钮的 child/icon/label/style 参数，渲染成 Quartz 按钮。
/// 新代码请直接用 QzButton。
class QzLegacyButton extends StatelessWidget {
  const QzLegacyButton({
    super.key,
    this.child,
    this.onPressed,
    this.kind = QzButtonKind.primary,
    this.style,
  }) : icon = null,
       label = null;

  const QzLegacyButton.tonal({
    super.key,
    this.child,
    this.onPressed,
    this.style,
  }) : kind = QzButtonKind.plain,
       icon = null,
       label = null;

  const QzLegacyButton.icon({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.kind = QzButtonKind.primary,
    this.style,
  }) : child = null;

  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final VoidCallback? onPressed;
  final QzButtonKind kind;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final (bg, fg, border) = switch (kind) {
      QzButtonKind.primary => (t.accent, Colors.white, null),
      QzButtonKind.plain => (t.raised, t.text, t.borderStrong),
      QzButtonKind.danger => (Colors.transparent, t.err, t.borderStrong),
      QzButtonKind.ghost => (Colors.transparent, t.accent, null),
    };
    final iconWidget = icon is Icon
        ? QzIcon(
            qzAssetForMaterialIcon((icon! as Icon).icon),
            size: 18,
            color: fg,
          )
        : icon ?? const SizedBox.shrink();
    final content =
        child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme.merge(
              data: IconThemeData(color: fg, size: 18),
              child: iconWidget,
            ),
            const SizedBox(width: 6),
            label ?? const SizedBox.shrink(),
          ],
        );
    return QzPressable(
      onTap: onPressed,
      enabled: onPressed != null,
      borderRadius: BorderRadius.circular(QuartzRadii.button),
      semanticLabel: label is Text ? (label as Text).data : null,
      scaleOnPress: true,
      child: AnimatedOpacity(
        opacity: onPressed == null ? .4 : 1,
        duration: QuartzMotion.fast,
        child: Container(
          height: QuartzSizes.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(QuartzRadii.button),
            border: border == null ? null : Border.all(color: border),
          ),
          child: DefaultTextStyle.merge(
            style: QuartzType.button.copyWith(color: fg),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}

/// Web 风格下划线页签（对应 LuCI .cbi-tabmenu）：左对齐、accent 2px 下划线。
class QzTabs<T> extends StatelessWidget {
  const QzTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.margin = EdgeInsets.zero,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Container(
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final v in values)
              QzPressable(
                onTap: () => onChanged(v),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                selected: v == selected,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: v == selected ? t.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labelOf(v),
                    style: QuartzType.body.copyWith(
                      fontSize: 13.5,
                      color: v == selected ? t.text : t.muted,
                      fontWeight: v == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QzDivider extends StatelessWidget {
  const QzDivider({super.key, this.indent = 0, this.endIndent = 0, this.color});

  final double indent;
  final double endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(height: 1, color: color ?? t.border),
    );
  }
}
