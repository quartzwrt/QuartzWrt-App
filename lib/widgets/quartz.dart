// Quartz 通用组件（与 design/preview.html 的视觉规格一致）。
import 'package:flutter/material.dart';

import '../core/theme.dart';

class QuartzCard extends StatelessWidget {
  const QuartzCard({super.key, this.title, this.trailing, required this.child, this.padding});

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: dark ? QuartzColors.darkPanel : QuartzColors.lightPanel,
        borderRadius: BorderRadius.circular(QuartzRadii.md),
        border: Border.all(
          color: dark ? const Color(0x17FFFFFF) : const Color(0x14000000),
        ),
      ),
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: .55),
                        fontWeight: FontWeight.w600,
                        letterSpacing: .35,
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
  const StatusDot(this.kind, {super.key, this.margin = const EdgeInsets.only(right: 7)});

  final DotKind kind;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      DotKind.ok => QuartzColors.ok,
      DotKind.warn => QuartzColors.warn,
      DotKind.err => QuartzColors.err,
      DotKind.off => Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
    };
    return Padding(
      padding: margin,
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
  });

  final String label;
  final String value;
  final bool first;
  final Color? valueColor;
  final bool valueMono;
  final Widget? valueWidget;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.brightness == Brightness.dark
        ? const Color(0x14FFFFFF)
        : const Color(0x11000000);
    return Container(
      decoration: first ? null : BoxDecoration(border: Border(top: BorderSide(color: divider))),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              if (valueWidget != null)
                valueWidget!
              else
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                    fontFeatures: valueMono ? const [FontFeature.tabularFigures()] : null,
                  ),
                ),
            ],
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sub!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .5),
                ),
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
    final color = switch (kind) {
      DotKind.err => QuartzColors.err,
      _ => QuartzColors.warn,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(QuartzRadii.md),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kind == DotKind.err ? Icons.error_outline : Icons.warning_amber_outlined,
              size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))),
              ],
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: dark ? QuartzColors.darkBgBase : const Color(0xFFE6E6EB),
        borderRadius: BorderRadius.circular(QuartzRadii.sm + 1),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: v == selected
                      ? BoxDecoration(
                          color: dark ? QuartzColors.darkRaised : Colors.white,
                          borderRadius: BorderRadius.circular(QuartzRadii.sm),
                          boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 3, offset: Offset(0, 1))],
                        )
                      : null,
                  child: Text(
                    labelOf(v),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: v == selected ? FontWeight.w600 : FontWeight.w400,
                      color: v == selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: .55),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
          fontWeight: FontWeight.w600,
          letterSpacing: .35,
        ),
      ),
    );
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
}) async {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final r = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: dark ? QuartzColors.darkRaised : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .6),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: danger
                      ? FilledButton.styleFrom(
                          backgroundColor: QuartzColors.err.withValues(alpha: .14),
                          foregroundColor: QuartzColors.err,
                          side: BorderSide(color: QuartzColors.err.withValues(alpha: .35)),
                        )
                      : null,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return r == true;
}
