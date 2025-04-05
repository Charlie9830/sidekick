import 'package:flutter/material.dart';

/// Provided a Controller class that coordinates the [isDragging] state to child widgets.
class DragProxyController extends StatefulWidget {
  final Widget child;
  const DragProxyController({super.key, required this.child});

  @override
  State<DragProxyController> createState() => _DragProxyControllerState();
}

class _DragProxyControllerState extends State<DragProxyController> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DragProxyMessenger(
      setDragState: (dragState) {
        if (mounted == false) {
          return;
        }

        setState(() => _isDragging = dragState);
      },
      isDragging: _isDragging,
      child: widget.child,
    );
  }
}

/// Faciliates communcation between child [DraggableProxy] widgets and the [DragProxyController].
class DragProxyMessenger extends InheritedWidget {
  const DragProxyMessenger({
    super.key,
    required Widget child,
    required this.setDragState,
    required this.isDragging,
  }) : super(child: child);

  final void Function(bool dragState) setDragState;
  final bool isDragging;

  static DragProxyMessenger? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DragProxyMessenger>();
  }

  @override
  bool updateShouldNotify(DragProxyMessenger oldWidget) {
    return setDragState != oldWidget.setDragState ||
        isDragging != oldWidget.isDragging;
  }
}

/// Proxy class for [Draggable], hooks certain events in order to coordinate the [isDragging] state to the closest ancestor [DragProxyController].
class DraggableProxy<T extends Object> extends StatelessWidget {
  final Widget child;
  final Widget feedback;
  final T? data;

  const DraggableProxy({
    super.key,
    required this.child,
    required this.feedback,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    assert(DragProxyMessenger.of(context) != null,
        '[DraggableProxy] must have an ancestor [DragProxyController]');

    return Draggable<T>(
      feedback: feedback,
      data: data,
      onDragStarted: () => DragProxyMessenger.of(context)!.setDragState(true),
      onDragCompleted: () {
        DragProxyMessenger.of(context)?.setDragState(false);
      },
      onDraggableCanceled: (_, __) {
        DragProxyMessenger.of(context)?.setDragState(false);
      },
      child: child,
    );
  }
}

/// Proxy class for [DragTarget]. Currently no hooked behaviour, thin proxy only.
class DragTargetProxy<T extends Object> extends StatelessWidget {
  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final DragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// Called when a piece of data enters the target. This will be followed by
  /// either [onAccept] and [onAcceptWithDetails], if the data is dropped, or
  /// [onLeave], if the drag leaves the target.
  ///
  /// Equivalent to [onWillAccept], but with information, including the data,
  /// in a [DragTargetDetails].
  ///
  /// Must not be provided if [onWillAccept] is provided.
  final DragTargetWillAcceptWithDetails<T>? onWillAcceptWithDetails;

  /// Called when an acceptable piece of data was dropped over this drag target.
  /// It will not be called if `data` is `null`.
  ///
  /// Equivalent to [onAccept], but with information, including the data, in a
  /// [DragTargetDetails].
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final DragTargetLeave<T>? onLeave;

  /// Called when a [Draggable] moves within this [DragTarget]. It will not be
  /// called if `data` is `null`.
  ///
  /// This includes entering and leaving the target.
  final DragTargetMove<T>? onMove;

  /// How to behave during hit testing.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  final HitTestBehavior hitTestBehavior;

  const DragTargetProxy({
    super.key,
    required this.builder,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.onWillAcceptWithDetails,
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      builder: builder,
      onWillAcceptWithDetails: onWillAcceptWithDetails,
      onAcceptWithDetails: onAcceptWithDetails,
      onLeave: onLeave,
      onMove: onMove,
      hitTestBehavior: hitTestBehavior,
    );
  }
}
