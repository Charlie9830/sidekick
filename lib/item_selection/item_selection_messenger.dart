import 'package:flutter/material.dart';

class ItemSelectionMessenger<T> extends InheritedWidget {
  final void Function(PointerEvent e, T value) onItemPointerEvent;
  final void Function(T itemId, int? itemIndex) onIndexRegistered;

  const ItemSelectionMessenger({
    super.key,
    required Widget child,
    required this.onItemPointerEvent,
    required this.onIndexRegistered,
  }) : super(child: child);

  void registerItemIndex(T itemId, int? index) {
    onIndexRegistered(itemId, index);
  }

  static ItemSelectionMessenger? maybeOf<T>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<ItemSelectionMessenger<T>>();
  }

  @override
  bool updateShouldNotify(ItemSelectionMessenger oldWidget) {
    return oldWidget.onItemPointerEvent != onItemPointerEvent;
  }
}
