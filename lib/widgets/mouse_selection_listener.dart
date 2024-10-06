import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MouseSelectionListener extends StatefulWidget {
  final Widget child;
  final void Function()? onSelectionDragOver;

  final void Function()? onTapDown;
  final void Function()? onTapUp;

  const MouseSelectionListener({
    super.key,
    required this.child,
    this.onSelectionDragOver,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  State<MouseSelectionListener> createState() => _MouseSelectionListenerState();
}

class _MouseSelectionListenerState extends State<MouseSelectionListener> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: _handlePointerUp,
      child: MouseRegion(
        onEnter: _handleOnEnter,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onVerticalDragStart: _handleDragStart,
          child: widget.child,
        ),
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    widget.onSelectionDragOver?.call();
  }

  void _handleTapDown(TapDownDetails details) {
    widget.onTapDown?.call();
  }

  void _handlePointerUp(PointerUpEvent event) {
    widget.onTapUp?.call();
  }

  void _handleOnEnter(PointerEnterEvent event) {
    if (event.down) {
      widget.onSelectionDragOver?.call();
    }
  }
}
