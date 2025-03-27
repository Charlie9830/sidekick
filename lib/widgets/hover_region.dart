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
