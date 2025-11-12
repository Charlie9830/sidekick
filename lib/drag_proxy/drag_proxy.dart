import 'package:flutter/gestures.dart';
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
class DraggableProxy<T extends Object> extends StatefulWidget {
  /// The data that will be dropped by this draggable.
  final T? data;

  /// The [Axis] to restrict this draggable's movement, if specified.
  ///
  /// When axis is set to [Axis.horizontal], this widget can only be dragged
  /// horizontally. Behavior is similar for [Axis.vertical].
  ///
  /// Defaults to allowing drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// When null, allows drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// For the direction of gestures this widget competes with to start a drag
  /// event, see [Draggable.affinity].
  final Axis? axis;

  /// The widget below this widget in the tree.
  ///
  /// This widget displays [child] when zero drags are under way. If
  /// [childWhenDragging] is non-null, this widget instead displays
  /// [childWhenDragging] when one or more drags are underway. Otherwise, this
  /// widget always displays [child].
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The widget to display instead of [child] when one or more drags are under way.
  ///
  /// If this is null, then this widget will always display [child] (and so the
  /// drag source representation will not change while a drag is under
  /// way).
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  final Widget? childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  ///
  /// See [child] and [childWhenDragging] for information about what is shown
  /// at the location of the [Draggable] itself when a drag is under way.
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;

  /// A strategy that is used by this draggable to get the anchor offset when it
  /// is dragged.
  ///
  /// The anchor offset refers to the distance between the users' fingers and
  /// the [feedback] widget when this draggable is dragged.
  ///
  /// This property's value is a function that implements [DragAnchorStrategy].
  /// There are two built-in functions that can be used:
  ///
  ///  * [childDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the original child.
  ///
  ///  * [pointerDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the touch that started the drag.
  ///
  /// Defaults to [childDragAnchorStrategy].
  final DragAnchorStrategy dragAnchorStrategy;

  /// Whether the semantics of the [feedback] widget is ignored when building
  /// the semantics tree.
  ///
  /// This value should be set to false when the [feedback] widget is intended
  /// to be the same object as the [child]. Placing a [GlobalKey] on this
  /// widget will ensure semantic focus is kept on the element as it moves in
  /// and out of the feedback position.
  ///
  /// Defaults to true.
  final bool ignoringFeedbackSemantics;

  /// Whether the [feedback] widget is ignored during hit testing.
  ///
  /// Regardless of whether this widget is ignored during hit testing, it will
  /// still consume space during layout and be visible during painting.
  ///
  /// Defaults to true.
  final bool ignoringFeedbackPointer;

  /// Controls how this widget competes with other gestures to initiate a drag.
  ///
  /// If affinity is null, this widget initiates a drag as soon as it recognizes
  /// a tap down gesture, regardless of any directionality. If affinity is
  /// horizontal (or vertical), then this widget will compete with other
  /// horizontal (or vertical, respectively) gestures.
  ///
  /// For example, if this widget is placed in a vertically scrolling region and
  /// has horizontal affinity, pointer motion in the vertical direction will
  /// result in a scroll and pointer motion in the horizontal direction will
  /// result in a drag. Conversely, if the widget has a null or vertical
  /// affinity, pointer motion in any direction will result in a drag rather
  /// than in a scroll because the draggable widget, being the more specific
  /// widget, will out-compete the [Scrollable] for vertical gestures.
  ///
  /// For the directions this widget can be dragged in after the drag event
  /// starts, see [Draggable.axis].
  final Axis? affinity;

  /// How many simultaneous drags to support.
  ///
  /// When null, no limit is applied. Set this to 1 if you want to only allow
  /// the drag source to have one item dragged at a time. Set this to 0 if you
  /// want to prevent the draggable from actually being dragged.
  ///
  /// If you set this property to 1, consider supplying an "empty" widget for
  /// [childWhenDragging] to create the illusion of actually moving [child].
  final int? maxSimultaneousDrags;

  /// Called when the draggable starts being dragged.
  final VoidCallback? onDragStarted;

  /// Called when the draggable is dragged.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true), and if this widget has actually moved.
  final DragUpdateCallback? onDragUpdate;

  /// Called when the draggable is dropped without being accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up being canceled, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final DraggableCanceledCallback? onDraggableCanceled;

  /// Called when the draggable is dropped and accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up completing, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final VoidCallback? onDragCompleted;

  /// Called when the draggable is dropped.
  ///
  /// The velocity and offset at which the pointer was moving when it was
  /// dropped is available in the [DraggableDetails]. Also included in the
  /// `details` is whether the draggable's [DragTarget] accepted it.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true).
  final DragEndCallback? onDragEnd;

  /// Whether the feedback widget will be put on the root [Overlay].
  ///
  /// When false, the feedback widget will be put on the closest [Overlay]. When
  /// true, the [feedback] widget will be put on the farthest (aka root)
  /// [Overlay].
  ///
  /// Defaults to false.
  final bool rootOverlay;

  /// How to behave during hit test.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior hitTestBehavior;

  final Duration? delay;

  const DraggableProxy(
      {super.key,
      required this.child,
      required this.feedback,
      this.data,
      this.axis,
      this.childWhenDragging,
      this.feedbackOffset = Offset.zero,
      this.dragAnchorStrategy = childDragAnchorStrategy,
      this.affinity,
      this.maxSimultaneousDrags,
      this.onDragStarted,
      this.onDragUpdate,
      this.onDraggableCanceled,
      this.onDragEnd,
      this.onDragCompleted,
      this.ignoringFeedbackSemantics = true,
      this.ignoringFeedbackPointer = true,
      this.rootOverlay = false,
      this.hitTestBehavior = HitTestBehavior.deferToChild,
      this.delay})
      : assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0);

  @override
  State<DraggableProxy> createState() => _DraggableProxyState();
}

class _DraggableProxyState<T extends Object> extends State<DraggableProxy<T>> {
  DragProxyMessenger? _parentMessenger;

  @override
  Widget build(BuildContext context) {
    assert(DragProxyMessenger.of(context) != null,
        '[DraggableProxy] must have an ancestor [DragProxyController]');

    return Draggable<T>(
      feedback: widget.feedback,
      axis: widget.axis,
      childWhenDragging: widget.childWhenDragging,
      data: widget.data,
      dragAnchorStrategy: widget.dragAnchorStrategy,
      feedbackOffset: widget.feedbackOffset,
      ignoringFeedbackPointer: widget.ignoringFeedbackPointer,
      ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
      key: widget.key,
      maxSimultaneousDrags: widget.maxSimultaneousDrags,
      onDragStarted: () {
        _parentMessenger = DragProxyMessenger.of(context);
        _parentMessenger!.setDragState(true);
        widget.onDragStarted?.call();
      },
      onDragCompleted: () {
        _parentMessenger?.setDragState(false);
        widget.onDragCompleted?.call();

        _parentMessenger = null;
      },
      onDraggableCanceled: (velocity, offset) {
        _parentMessenger?.setDragState(false);
        widget.onDraggableCanceled?.call(velocity, offset);

        _parentMessenger = null;
      },
      onDragEnd: (details) {
        _parentMessenger?.setDragState(false);
        widget.onDragEnd?.call(details);

        _parentMessenger = null;
      },
      onDragUpdate: widget.onDragUpdate,
      child: widget.child,
    );
  }
}

/// Proxy class for [LongPressDraggable], hooks certain events in order to coordinate the [isDragging] state to the closest ancestor [DragProxyController].
class LongPressDraggableProxy<T extends Object> extends StatefulWidget {
  /// The data that will be dropped by this draggable.
  final T? data;

  /// The [Axis] to restrict this draggable's movement, if specified.
  ///
  /// When axis is set to [Axis.horizontal], this widget can only be dragged
  /// horizontally. Behavior is similar for [Axis.vertical].
  ///
  /// Defaults to allowing drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// When null, allows drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// For the direction of gestures this widget competes with to start a drag
  /// event, see [Draggable.affinity].
  final Axis? axis;

  /// The widget below this widget in the tree.
  ///
  /// This widget displays [child] when zero drags are under way. If
  /// [childWhenDragging] is non-null, this widget instead displays
  /// [childWhenDragging] when one or more drags are underway. Otherwise, this
  /// widget always displays [child].
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The widget to display instead of [child] when one or more drags are under way.
  ///
  /// If this is null, then this widget will always display [child] (and so the
  /// drag source representation will not change while a drag is under
  /// way).
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  final Widget? childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  ///
  /// See [child] and [childWhenDragging] for information about what is shown
  /// at the location of the [Draggable] itself when a drag is under way.
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;

  /// A strategy that is used by this draggable to get the anchor offset when it
  /// is dragged.
  ///
  /// The anchor offset refers to the distance between the users' fingers and
  /// the [feedback] widget when this draggable is dragged.
  ///
  /// This property's value is a function that implements [DragAnchorStrategy].
  /// There are two built-in functions that can be used:
  ///
  ///  * [childDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the original child.
  ///
  ///  * [pointerDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the touch that started the drag.
  ///
  /// Defaults to [childDragAnchorStrategy].
  final DragAnchorStrategy dragAnchorStrategy;

  /// Whether the semantics of the [feedback] widget is ignored when building
  /// the semantics tree.
  ///
  /// This value should be set to false when the [feedback] widget is intended
  /// to be the same object as the [child]. Placing a [GlobalKey] on this
  /// widget will ensure semantic focus is kept on the element as it moves in
  /// and out of the feedback position.
  ///
  /// Defaults to true.
  final bool ignoringFeedbackSemantics;

  /// Whether the [feedback] widget is ignored during hit testing.
  ///
  /// Regardless of whether this widget is ignored during hit testing, it will
  /// still consume space during layout and be visible during painting.
  ///
  /// Defaults to true.
  final bool ignoringFeedbackPointer;

  /// Controls how this widget competes with other gestures to initiate a drag.
  ///
  /// If affinity is null, this widget initiates a drag as soon as it recognizes
  /// a tap down gesture, regardless of any directionality. If affinity is
  /// horizontal (or vertical), then this widget will compete with other
  /// horizontal (or vertical, respectively) gestures.
  ///
  /// For example, if this widget is placed in a vertically scrolling region and
  /// has horizontal affinity, pointer motion in the vertical direction will
  /// result in a scroll and pointer motion in the horizontal direction will
  /// result in a drag. Conversely, if the widget has a null or vertical
  /// affinity, pointer motion in any direction will result in a drag rather
  /// than in a scroll because the draggable widget, being the more specific
  /// widget, will out-compete the [Scrollable] for vertical gestures.
  ///
  /// For the directions this widget can be dragged in after the drag event
  /// starts, see [Draggable.axis].
  final Axis? affinity;

  /// How many simultaneous drags to support.
  ///
  /// When null, no limit is applied. Set this to 1 if you want to only allow
  /// the drag source to have one item dragged at a time. Set this to 0 if you
  /// want to prevent the draggable from actually being dragged.
  ///
  /// If you set this property to 1, consider supplying an "empty" widget for
  /// [childWhenDragging] to create the illusion of actually moving [child].
  final int? maxSimultaneousDrags;

  /// Called when the draggable starts being dragged.
  final VoidCallback? onDragStarted;

  /// Called when the draggable is dragged.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true), and if this widget has actually moved.
  final DragUpdateCallback? onDragUpdate;

  /// Called when the draggable is dropped without being accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up being canceled, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final DraggableCanceledCallback? onDraggableCanceled;

  /// Called when the draggable is dropped and accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up completing, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final VoidCallback? onDragCompleted;

  /// Called when the draggable is dropped.
  ///
  /// The velocity and offset at which the pointer was moving when it was
  /// dropped is available in the [DraggableDetails]. Also included in the
  /// `details` is whether the draggable's [DragTarget] accepted it.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true).
  final DragEndCallback? onDragEnd;

  /// Whether the feedback widget will be put on the root [Overlay].
  ///
  /// When false, the feedback widget will be put on the closest [Overlay]. When
  /// true, the [feedback] widget will be put on the farthest (aka root)
  /// [Overlay].
  ///
  /// Defaults to false.
  final bool rootOverlay;

  /// How to behave during hit test.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior hitTestBehavior;

  final Duration? delay;

  const LongPressDraggableProxy(
      {super.key,
      required this.child,
      required this.feedback,
      this.data,
      this.axis,
      this.childWhenDragging,
      this.feedbackOffset = Offset.zero,
      this.dragAnchorStrategy = childDragAnchorStrategy,
      this.affinity,
      this.maxSimultaneousDrags,
      this.onDragStarted,
      this.onDragUpdate,
      this.onDraggableCanceled,
      this.onDragEnd,
      this.onDragCompleted,
      this.ignoringFeedbackSemantics = true,
      this.ignoringFeedbackPointer = true,
      this.rootOverlay = false,
      this.hitTestBehavior = HitTestBehavior.deferToChild,
      this.delay})
      : assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0);

  @override
  State<LongPressDraggableProxy> createState() =>
      _LongPressDraggableProxyState();
}

class _LongPressDraggableProxyState<T extends Object>
    extends State<LongPressDraggableProxy<T>> {
  DragProxyMessenger? _parentMessenger;

  @override
  Widget build(BuildContext context) {
    assert(DragProxyMessenger.of(context) != null,
        '[DraggableProxy] must have an ancestor [DragProxyController]');

    return LongPressDraggable<T>(
      delay: const Duration(milliseconds: 250),
      feedback: widget.feedback,
      axis: widget.axis,
      childWhenDragging: widget.childWhenDragging,
      data: widget.data,
      dragAnchorStrategy: widget.dragAnchorStrategy,
      feedbackOffset: widget.feedbackOffset,
      ignoringFeedbackPointer: widget.ignoringFeedbackPointer,
      ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
      key: widget.key,
      maxSimultaneousDrags: widget.maxSimultaneousDrags,
      onDragStarted: () {
        _parentMessenger = DragProxyMessenger.of(context);
        _parentMessenger!.setDragState(true);
        widget.onDragStarted?.call();
      },
      onDragCompleted: () {
        _parentMessenger?.setDragState(false);
        widget.onDragCompleted?.call();

        _parentMessenger = null;
      },
      onDraggableCanceled: (velocity, offset) {
        _parentMessenger?.setDragState(false);
        widget.onDraggableCanceled?.call(velocity, offset);

        _parentMessenger = null;
      },
      onDragEnd: (details) {
        _parentMessenger?.setDragState(false);
        widget.onDragEnd?.call(details);

        _parentMessenger = null;
      },
      onDragUpdate: widget.onDragUpdate,
      child: widget.child,
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
