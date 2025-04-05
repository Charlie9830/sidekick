import 'package:flutter/material.dart';
import 'package:sidekick/widgets/hover_region.dart';

class DragHoverOverlay extends StatefulWidget {
  final Widget child;
  final Widget overlay;
  const DragHoverOverlay(
      {super.key, required this.child, required this.overlay});

  @override
  State<DragHoverOverlay> createState() => _DragHoverOverlayState();
}

class _DragHoverOverlayState extends State<DragHoverOverlay> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      onHoverChanged: (isHovering, isMouseDown) =>
          setState(() => _isDragging = isHovering && isMouseDown),
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
                child: Container(
                    color: Theme.of(context).cardColor.withAlpha(128))),
          if (_isDragging) Positioned.fill(child: widget.overlay),
        ],
      ),
    );
  }
}
