import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

enum ActivationType {
  pointerUp,
  pointerDown,
}

class ItemSelectionListener<T> extends StatelessWidget {
  final Widget child;
  final T value;
  final bool enabled;
  final ActivationType activationType;

  const ItemSelectionListener({
    super.key,
    required this.child,
    required this.value,
    this.enabled = true,
    this.activationType = ActivationType.pointerUp,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerUp: enabled && activationType == ActivationType.pointerUp
          ? (e) => ItemSelectionMessenger.maybeOf<T>(context)
              ?.onItemPointerEvent(e, value)
          : null,
      onPointerDown: enabled && activationType == ActivationType.pointerDown
          ? (e) => ItemSelectionMessenger.maybeOf<T>(context)
              ?.onItemPointerEvent(e, value)
          : null,
      child: child,
    );
  }
}
