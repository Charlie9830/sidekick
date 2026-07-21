import 'package:flutter/material.dart';

class ItemSelectionMessenger<T> extends InheritedWidget {
  final void Function(PointerEvent e, T value) onItemPointerEvent;
  final void Function(T itemId, int? itemIndex) onIndexRegistered;
  final void Function(T itemId) onIndexUnregistered;

  const ItemSelectionMessenger({
    super.key,
    required super.child,
    required this.onItemPointerEvent,
    required this.onIndexRegistered,
    required this.onIndexUnregistered,
  });

  void registerItemIndex(T itemId, int? index) {
    onIndexRegistered(itemId, index);
  }

  void unregisterItemIndex(T itemId) {
    onIndexUnregistered(itemId);
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
