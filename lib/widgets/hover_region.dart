import 'package:flutter/material.dart';

typedef OnHoverChangedCallback = void Function(bool hovering, bool mouseDown);

class HoverRegion extends StatelessWidget {
  final Widget? child;
  final OnHoverChangedCallback? onHoverChanged;
  const HoverRegion({Key? key, this.child, this.onHoverChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => onHoverChanged?.call(true, e.down),
      onExit: (e) => onHoverChanged?.call(false, e.down),
      child: child,
    );
  }
}

typedef HoverRegionWidgetBuilder = Widget Function(
    BuildContext context, bool isHovering);

class HoverRegionBuilder extends StatefulWidget {
  final HoverRegionWidgetBuilder builder;

  const HoverRegionBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<HoverRegionBuilder> createState() => _HoverRegionBuilderState();
}

class _HoverRegionBuilderState extends State<HoverRegionBuilder> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      onHoverChanged: (hovering, mousedown) =>
          setState(() => _isHovering = hovering),
      child: widget.builder(context, _isHovering),
    );
  }
}
