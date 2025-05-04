import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/widgets/hover_region.dart';

class DragOverlayRegion extends StatelessWidget {
  final Widget child;
  final Widget childWhenDraggingOver;

  const DragOverlayRegion({
    super.key,
    required this.child,
    required this.childWhenDraggingOver,
  });

  @override
  Widget build(BuildContext context) {
    assert(DragProxyMessenger.of(context) != null,
        'A [DragProxyController] must be provided as an ancestor to a [DragOverlayRegion]');

    /// Thin Drag Target used to only listen for Dragging objects passing over this region.
    return HoverRegionBuilder(builder: (context, hovering) {
      return DragTarget(builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            child,
            if (DragProxyMessenger.of(context)!.isDragging && hovering)
              Positioned.fill(child: childWhenDraggingOver),
          ],
        );
      });
    });
  }
}
