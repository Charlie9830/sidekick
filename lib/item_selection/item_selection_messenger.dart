import 'package:flutter/material.dart';

class ItemSelectionMessenger<T> extends InheritedWidget {
  final void Function(PointerEvent e, T value) onItemPointerEvent;

  const ItemSelectionMessenger({
    super.key,
    required Widget child,
    required this.onItemPointerEvent,
  }) : super(child: child);

  static ItemSelectionMessenger? of<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ItemSelectionMessenger<T>>();
  }

  @override
  bool updateShouldNotify(ItemSelectionMessenger oldWidget) {
    return oldWidget.onItemPointerEvent != onItemPointerEvent;
  }
}
