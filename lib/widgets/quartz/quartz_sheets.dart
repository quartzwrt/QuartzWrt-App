// Quartz 底部层 / 确认层 / Toast：不用 Material Dialog / BottomSheet / SnackBar。
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'quartz_controls.dart';
import 'quartz_icons.dart';

/// 设计稿底部层：scrim .45、顶部圆角 20、raised 底、顶部强描边、handle 40×4.5。
Future<T?> showQzSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  // 兼容旧 showModalBottomSheet 调用点的参数；视觉统一由 QzSheetPanel 决定。
  bool? isDismissible,
  bool isScrollControlled = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final t = QuartzTokens.of(context);
  final canDismiss = dismissible && (isDismissible ?? true);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    barrierDismissible: canDismiss,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: t.scrim,
    transitionDuration: QuartzMotion.sheet,
    pageBuilder: (ctx, animation, secondary) {
      final size = MediaQuery.sizeOf(ctx);
      final insets = MediaQuery.viewInsetsOf(ctx);
      final content = Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedPadding(
          duration: QuartzMotion.fast,
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * .92),
            child: QzSheetPanel(child: builder(ctx)),
          ),
        ),
      );
      return canDismiss ? content : PopScope(canPop: false, child: content);
    },
    transitionBuilder: (ctx, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class QzSheetPanel extends StatelessWidget {
  const QzSheetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 12),
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.raised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(QuartzRadii.sheet),
          ),
          border: Border(top: BorderSide(color: t.borderStrong)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
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
                      color: t.faint,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (scrollable)
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(child: child),
                  )
                else
                  child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 危险/一般确认层（替代 showConfirmSheet 的 Material 按钮与 sheet 路由）。
Future<bool> showQzConfirm(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  String cancelLabel = '',
  bool danger = false,
}) async {
  final l10n = MaterialLocalizations.of(context);
  final r = await showQzSheet<bool>(
    context,
    builder: (ctx) {
      final t = QuartzTokens.of(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: QuartzType.heroTitle.copyWith(color: t.text),
          ),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: QuartzType.sub.copyWith(color: t.muted, height: 1.55),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QzButton(
                  label: cancelLabel.isEmpty
                      ? l10n.cancelButtonLabel
                      : cancelLabel,
                  kind: QzButtonKind.plain,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QzButton(
                  label: confirmLabel,
                  kind: danger ? QzButtonKind.danger : QzButtonKind.primary,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      );
    },
  );
  return r == true;
}

enum QzToastKind { info, ok, err, warn }

/// 轻量 Toast：不依赖 ScaffoldMessenger / SnackBar。
void showQzToast(
  BuildContext context,
  String message, {
  QzToastKind kind = QzToastKind.info,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final bottom = MediaQuery.paddingOf(context).bottom + 84;
  late final OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: _QzToastOverlay(message: message, kind: kind, onDone: remove),
      ),
    ),
  );
  overlay.insert(entry);
}

class _QzToastOverlay extends StatefulWidget {
  const _QzToastOverlay({
    required this.message,
    required this.kind,
    required this.onDone,
  });

  final String message;
  final QzToastKind kind;
  final VoidCallback onDone;

  @override
  State<_QzToastOverlay> createState() => _QzToastOverlayState();
}

class _QzToastOverlayState extends State<_QzToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, child) {
        final t = _c.value;
        final fade = t < .08 ? t / .08 : (t > .92 ? (1 - t) / .08 : 1.0);
        final opacity = fade.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - opacity) * 8),
            child: child,
          ),
        );
      },
      child: QzToast(message: widget.message, kind: widget.kind),
    );
  }
}

class QzToast extends StatelessWidget {
  const QzToast({
    super.key,
    required this.message,
    this.kind = QzToastKind.info,
  });

  final String message;
  final QzToastKind kind;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final (color, icon) = switch (kind) {
      QzToastKind.ok => (t.ok, QzIcons.check),
      QzToastKind.err => (t.err, QzIcons.warning),
      QzToastKind.warn => (t.warn, QzIcons.warning),
      QzToastKind.info => (t.accent, QzIcons.info),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: t.raised,
        borderRadius: BorderRadius.circular(QuartzRadii.md),
        border: Border.all(color: t.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          QzIcon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: QuartzType.body.copyWith(color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}
