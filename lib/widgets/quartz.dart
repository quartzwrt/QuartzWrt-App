// Quartz 通用组件（设计稿 ia-v2-preview.html 规格）。
//
// 这里保留旧 API（QuartzCard/StatusDot/KvRow/InfoBanner/SegmentBar/showConfirmSheet），
// 新组件在 quartz/ 子库中；页面统一从本文件导入。
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../format.dart';
import 'quartz/quartz_controls.dart';
import 'quartz/quartz_icons.dart';
import 'quartz/quartz_layout.dart';
import 'quartz/quartz_sheets.dart';

export 'quartz/quartz_controls.dart';
export 'quartz/quartz_icons.dart';
export 'quartz/quartz_layout.dart';
export 'quartz/quartz_refresh.dart';
export 'quartz/quartz_sheets.dart';
export 'quartz/quartz_tab_bar.dart';

class QuartzCard extends StatelessWidget {
  const QuartzCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return QzPanel(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: QuartzType.bodyStrong.copyWith(
                        color: t.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

enum DotKind { ok, warn, err, off }

class StatusDot extends StatelessWidget {
  const StatusDot(
    this.kind, {
    super.key,
    this.margin = const EdgeInsets.only(right: 7),
  });

  final DotKind kind;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final color = switch (kind) {
      DotKind.ok => t.ok,
      DotKind.warn => t.warn,
      DotKind.err => t.err,
      DotKind.off => t.faint,
    };
    return Padding(
      padding: margin,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// IP 值（Dashboard `IpValue` 同款交互）：默认显示打码值，点按展开完整地址，
/// 再点收起；虚线底提示可交互。
class QzIpValue extends StatefulWidget {
  const QzIpValue({
    super.key,
    required this.value,
    this.style,
    this.showLabel = 'Click to reveal',
    this.hideLabel = 'Click to hide',
    this.textAlign = TextAlign.right,
  });

  final String value;
  final TextStyle? style;
  final String showLabel;
  final String hideLabel;
  final TextAlign textAlign;

  @override
  State<QzIpValue> createState() => _QzIpValueState();
}

class _QzIpValueState extends State<QzIpValue> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final empty = widget.value.isEmpty;
    final base =
        widget.style ??
        TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final text = Text(
      empty ? '—' : (_open ? widget.value : maskIp(widget.value)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.textAlign,
      style: base.copyWith(
        color: empty ? t.faint : (base.color ?? t.text),
        decoration: empty ? null : TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: _open ? t.accent : t.borderStrong,
        decorationThickness: 1,
      ),
    );
    if (empty) return text;
    final label = _open ? widget.hideLabel : widget.showLabel;
    return Tooltip(
      message: label,
      child: QzPressable(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(4),
        semanticLabel: label,
        child: text,
      ),
    );
  }
}

/// 键值行（首行不带分隔线）。
class KvRow extends StatelessWidget {
  const KvRow(
    this.label,
    this.value, {
    super.key,
    this.first = false,
    this.valueColor,
    this.valueMono = true,
    this.valueWidget,
    this.sub,
    this.pct,
    this.barColor,
  });

  final String label;
  final String value;
  final bool first;
  final Color? valueColor;
  final bool valueMono;
  final Widget? valueWidget;
  final String? sub;
  final double? pct;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final labelText = Text(
      label,
      style: QuartzType.body.copyWith(color: t.muted),
    );
    final valueStyle = valueMono
        ? TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: valueColor ?? t.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : QuartzType.bodyStrong.copyWith(color: valueColor ?? t.text);
    final valueText =
        valueWidget ??
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: valueStyle,
        );
    return Container(
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: t.border)),
            ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pct != null)
            Row(
              children: [
                SizedBox(width: 72, child: labelText),
                Expanded(
                  child: QzBar(
                    pct: (pct! / 100).clamp(0, 1),
                    color: barColor,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 124,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: valueText,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                labelText,
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: valueWidget ?? valueText,
                  ),
                ),
              ],
            ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sub!,
                style: QuartzType.caption.copyWith(color: t.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// 顶部信息横幅（降级/注意/错误）。
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.kind = DotKind.warn,
  });

  final String title;
  final String body;
  final DotKind kind;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final color = switch (kind) {
      DotKind.err => t.err,
      DotKind.ok => t.ok,
      DotKind.off => t.faint,
      _ => t.warn,
    };
    final radius = BorderRadius.circular(QuartzRadii.sm);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: radius,
        // Flutter 不允许带圆角的 Border 使用不同颜色的边；用内层左侧色条代替。
        border: Border.all(color: t.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QzIcon(
                        kind == DotKind.ok ? QzIcons.info : QzIcons.warning,
                        size: 17,
                        color: color,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: QuartzType.bodyStrong.copyWith(
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: QuartzType.sub.copyWith(
                                color: t.muted,
                                height: 1.55,
                              ),
                            ),
                          ],
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

class SegmentBar<T> extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return QzSegmented<T>(
      values: values,
      selected: selected,
      labelOf: labelOf,
      onChanged: onChanged,
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return QzSectionLabel(text);
  }
}

/// 破坏性/一般确认——底部确认层（DESIGN §3 交互约定）。
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  String cancelLabel = '',
  bool danger = false,
}) {
  return showQzConfirm(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    danger: danger,
  );
}
