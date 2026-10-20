// 自定义下拉刷新：Bouncing 物理 + 自绘 QzSpinner，不依赖 Material RefreshIndicator。
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'quartz_controls.dart';

class QzScrollBehavior extends ScrollBehavior {
  const QzScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class QzRefresh extends StatefulWidget {
  const QzRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<QzRefresh> createState() => _QzRefreshState();
}

class _QzRefreshState extends State<QzRefresh> {
  static const _trigger = 56.0;
  static const _max = 84.0;
  double _pull = 0;
  bool _busy = false;

  void _setPull(double v) {
    final next = v.clamp(0.0, _max);
    if ((next - _pull).abs() < .5) return;
    setState(() => _pull = next);
  }

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _pull = _trigger;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pull = 0;
        });
      }
    }
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final p = n.metrics.pixels;
      if (p < 0) {
        _setPull(-p);
      } else if (_pull > 0 && !_busy) {
        _setPull(0);
      }
    } else if (n is OverscrollNotification && n.overscroll < 0) {
      _setPull(_pull - n.overscroll);
    } else if (n is ScrollEndNotification && !_busy && _pull > 0) {
      if (_pull >= _trigger) {
        _run();
      } else {
        _setPull(0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final show = _busy || _pull > 0;
    return ScrollConfiguration(
      behavior: const QzScrollBehavior(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: Stack(
          children: [
            widget.child,
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: QuartzMotion.fast,
                  child: show
                      ? Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: t.panel,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.borderStrong),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2E000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: QzSpinner(
                                size: 16,
                                stroke: 2,
                                color: t.accent,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
