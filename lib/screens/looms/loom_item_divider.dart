import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/new_loom_drop_target_overlay.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

const double _kDefaultClosedHeight = 24;
const double _kExpandedClosedHeight = 124;

class LoomItemDivider extends StatefulWidget {
  final bool expand;
  const LoomItemDivider({
    super.key,
    required this.onDropAsFeeder,
    required this.onDropAsExtension,
    this.expand = false,
  });

  final void Function(
          List<OutletViewModel> outlets, Set<CableActionModifier> modifiers)
      onDropAsFeeder;
  final void Function(List<String> cableIds, Set<CableActionModifier> modifiers)
      onDropAsExtension;

  @override
  State<LoomItemDivider> createState() => _LoomItemDividerState();
}

class _LoomItemDividerState extends State<LoomItemDivider>
    with TickerProviderStateMixin {
  bool _draggingOver = false;

  late AnimationController _controller;

  late Animation<double> _height;

  late final Animation<double> _opacity;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 125));

    _initializeHeightAnimation();

    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1, curve: Curves.easeInOut)));

    super.initState();
  }

  @override
  void didUpdateWidget(covariant LoomItemDivider oldWidget) {
    if (oldWidget.expand != widget.expand) {
      _initializeHeightAnimation();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
        onHoverChanged: (hovering, mouseDown) {
          final incomingState =
              hovering && DragProxyMessenger.of(context)!.isDragging;
          final existingState = _draggingOver;

          if (incomingState == true && existingState == false) {
            _playForward();
          }

          if (incomingState == false && existingState == true) {
            _playReverse();
          }

          setState(() {
            _draggingOver = incomingState;
          });
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => SizedBox(
              height: _height.value,
              child: Opacity(
                  opacity: _opacity.value,
                  child: _draggingOver
                      ? NewLoomDropTargetOverlay(
                          onDropAsFeeder: widget.onDropAsFeeder,
                          onDropAsExtension: widget.onDropAsExtension,
                        )
                      : const SizedBox.shrink())),
        ));
  }

  void _initializeHeightAnimation() {
    _height = Tween<double>(
      begin: widget.expand ? _kExpandedClosedHeight : _kDefaultClosedHeight,
      end: 92,
    ).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.75, curve: Curves.easeInOut)),
    );
  }

  Future<void> _playForward() async {
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      // The animation got canceled, probably because it was disposed of.
    }
  }

  Future<void> _playReverse() async {
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      // The animation got canceled, probably because it was disposed of.
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }
}
