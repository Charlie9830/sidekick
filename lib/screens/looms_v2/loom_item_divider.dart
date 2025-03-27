import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms_v2/new_loom_drop_target_overlay.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class LoomItemDivider extends StatefulWidget {
  const LoomItemDivider({
    super.key,
    required this.onCustomDrop,
    required this.onPermanentDrop,
  });
  final void Function(List<OutletViewModel> outlets) onCustomDrop;
  final void Function(List<OutletViewModel> outlets) onPermanentDrop;

  @override
  State<LoomItemDivider> createState() => _LoomItemDividerState();
}

class _LoomItemDividerState extends State<LoomItemDivider>
    with TickerProviderStateMixin {
  bool _draggingOver = false;

  late AnimationController _controller;

  late final Animation<double> _height;

  late final Animation<double> _opacity;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 125));

    _height = Tween<double>(
      begin: 24,
      end: 92,
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.75, curve: Curves.easeInOut)));

    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1, curve: Curves.easeInOut)));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
        onHoverChanged: (hovering, mouseDown) {
          final incomingState = hovering && mouseDown;
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
                          onCustomDrop: widget.onCustomDrop,
                          onPermanentDrop: widget.onPermanentDrop)
                      : const SizedBox.shrink())),
        ));
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
