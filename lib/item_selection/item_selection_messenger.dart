import 'package:flutter/material.dart';

class ItemSelectionMessenger<T> extends InheritedWidget {
  final void Function(PointerUpEvent e, T value) onItemPointerUp;

  const ItemSelectionMessenger(
      {super.key, required Widget child, required this.onItemPointerUp})
      : super(child: child);

  static ItemSelectionMessenger? of<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ItemSelectionMessenger<T>>();
  }

  @override
  bool updateShouldNotify(ItemSelectionMessenger oldWidget) {
    return oldWidget.onItemPointerUp != onItemPointerUp;
  }
}
