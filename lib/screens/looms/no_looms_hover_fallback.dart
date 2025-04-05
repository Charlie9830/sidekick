import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/new_loom_drop_target_overlay.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class NoLoomsHoverFallback extends StatefulWidget {
  const NoLoomsHoverFallback({
    super.key,
    required this.onCustomDrop,
    required this.onPermanentDrop,
  });

  final void Function(List<OutletViewModel> outlets) onCustomDrop;
  final void Function(List<OutletViewModel> outlets) onPermanentDrop;

  @override
  State<NoLoomsHoverFallback> createState() => _NoLoomsHoverFallbackState();
}

class _NoLoomsHoverFallbackState extends State<NoLoomsHoverFallback> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      onHoverChanged: (hovering, mouseDown) => setState(() {
        _isDragHovering = hovering && mouseDown;
      }),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('To begin, drag outlets to here to create looms'),
          if (_isDragHovering)
            NewLoomDropTargetOverlay(
                onCustomDrop: widget.onCustomDrop,
                onPermanentDrop: widget.onPermanentDrop)
        ],
      ),
    );
  }
}
