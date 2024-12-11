import 'package:flutter/material.dart';

class ItemSelectionMessenger extends InheritedWidget {
  final void Function(PointerUpEvent e, Object value) onItemPointerUp;
  const ItemSelectionMessenger(
      {super.key, required this.child, required this.onItemPointerUp})
      : super(child: child);

  final Widget child;

  static ItemSelectionMessenger? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ItemSelectionMessenger>();
  }

  @override
  bool updateShouldNotify(ItemSelectionMessenger oldWidget) {
    return oldWidget.onItemPointerUp != onItemPointerUp;
  }
}
