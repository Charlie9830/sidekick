import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

enum ActivationType {
  pointerUp,
  pointerDown,
}

class ItemSelectionListener<T> extends StatefulWidget {
  final Widget child;
  final T itemId;
  final bool enabled;
  final ActivationType activationType;
  final int? index;

  const ItemSelectionListener({
    super.key,
    required this.child,
    required this.itemId,
    this.index,
    this.enabled = true,
    this.activationType = ActivationType.pointerUp,
  });

  @override
  State<ItemSelectionListener<T>> createState() =>
      _ItemSelectionListenerState<T>();
}

class _ItemSelectionListenerState<T> extends State<ItemSelectionListener<T>> {
  @override
  void didChangeDependencies() {
    assert(ItemSelectionMessenger.maybeOf<T>(context) != null,
        'Unable to find Ancestor [ItemSelectionMessenger]. Ensure an [ItemSelectionContainer]<$T> is provided as an Ancestor to this widget.');

    ItemSelectionMessenger.maybeOf<T>(context)
        ?.registerItemIndex(widget.itemId, widget.index);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerUp:
          widget.enabled && widget.activationType == ActivationType.pointerUp
              ? (e) => ItemSelectionMessenger.maybeOf<T>(context)
                  ?.onItemPointerEvent(e, widget.itemId)
              : null,
      onPointerDown:
          widget.enabled && widget.activationType == ActivationType.pointerDown
              ? (e) => ItemSelectionMessenger.maybeOf<T>(context)
                  ?.onItemPointerEvent(e, widget.itemId)
              : null,
      child: widget.child,
    );
  }
}
