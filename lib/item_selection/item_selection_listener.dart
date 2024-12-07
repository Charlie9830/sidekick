import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

class ItemSelectionListener extends StatelessWidget {
  final Widget child;
  final int index;

  const ItemSelectionListener({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    assert(ItemSelectionMessenger.of(context) != null,
        '[SelectionController] ancestor could not be found. Ensure a [SelectionController] has been provided as an ancestor widget to [ItemSelectionListener]');

    return Listener(
      onPointerUp: (e) =>
          ItemSelectionMessenger.of(context)!.onItemPointerUp(e, index),
      child: child,
    );
  }
}
