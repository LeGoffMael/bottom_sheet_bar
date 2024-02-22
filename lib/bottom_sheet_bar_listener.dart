import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Creates a [Listener] to track swipe gestures used to expand or collapse
/// a [BottomSheetBar]
///
/// - Tracks scolling and vertical-pan gestures
/// - Can be [locked] to stop listening to gestures
///
/// There's nothing specific to [BottomSheetBar] in here. This widget just
/// exposes a version of a [Listener] widget that is easier to use and read.
class BottomSheetBarListener extends StatefulWidget {
  final Widget child;

  /// Disables bottom-sheet from being expanded or collapsed with a swipe
  final bool locked;

  /// To not listen to child [ListView] scroll
  final ScrollController? scrollController;

  /// Triggered on [Listener.onPointerMove] and [Listener.onPointerSignal] (when
  ///  the [PointerSignalEvent] is a [PointerScrollEvent])
  final void Function(double dy) onScroll;

  /// Triggered on [Listener.onPointerDown] and [Listener.onPointerMove]
  final void Function(Duration timestamp, Offset position) onPosition;

  /// Trigger on [Listener.onPointerUp] and [Listener.onPointerCancel]
  final void Function() onEnd;

  const BottomSheetBarListener({
    Key? key,
    required this.locked,
    required this.child,
    required this.onScroll,
    required this.onPosition,
    required this.onEnd,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<BottomSheetBarListener> createState() => _BottomSheetBarListenerState();
}

class _BottomSheetBarListenerState extends State<BottomSheetBarListener> {
  int _currentDepth = 0;

  /// Do not handle scroll if come from child scroll view or
  /// if expanded view [scrollController] is not at the top
  void childScrollGuard(Function() call) {
    if (((widget.scrollController?.offset ?? 0) > 0) || _currentDepth > 0) {
      return;
    }
    call();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          _currentDepth = notification.depth;
          return notification.depth == 0;
        },
        child: Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerSignal: (ps) {
            if (!widget.locked && ps is PointerScrollEvent) {
              childScrollGuard(() => widget.onScroll(ps.delta.dy));
            }
          },
          onPointerDown: widget.locked
              ? null
              : (event) => childScrollGuard(
                    () => widget.onPosition(event.timeStamp, event.position),
                  ),
          onPointerMove: widget.locked
              ? null
              : (event) => childScrollGuard(
                    () {
                      widget.onPosition(event.timeStamp, event.position);
                      widget.onScroll(event.delta.dy);
                    },
                  ),
          onPointerUp: widget.locked ? null : (_) => widget.onEnd(),
          onPointerCancel: widget.locked ? null : (_) => widget.onEnd(),
          child: widget.child,
        ),
      );
}
