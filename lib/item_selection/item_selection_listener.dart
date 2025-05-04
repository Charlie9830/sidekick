import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

class ItemSelectionListener<T> extends StatelessWidget {
  final Widget child;
  final T value;
  final bool enabled;

  const ItemSelectionListener({
    super.key,
    required this.child,
    required this.value,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    assert(ItemSelectionMessenger.of<T>(context) != null,
        '[SelectionController] ancestor could not be found. Ensure a [SelectionController] has been provided as an ancestor widget to [ItemSelectionListener]');

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerUp: enabled
          ? (e) =>
              ItemSelectionMessenger.of<T>(context)!.onItemPointerUp(e, value)
          : null,
      child: child,
    );
  }
}
