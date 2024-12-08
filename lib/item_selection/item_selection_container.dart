import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_controller.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

class ItemSelectionContainer extends StatefulWidget {
  final Widget child;
  final ItemSelectionController controller;

  const ItemSelectionContainer({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ItemSelectionContainer> createState() => _ItemSelectionContainerState();
}

class _ItemSelectionContainerState extends State<ItemSelectionContainer> {
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    _keyboardFocusNode = FocusNode();
    _keyboardFocusNode.requestFocus();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ItemSelectionMessenger(
      onItemPointerUp: _handleItemPointerUp,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _dispatchKeyEvent,
        child: widget.child,
      ),
    );
  }

  void _handleItemPointerUp(PointerUpEvent e, int itemIndex) {
    widget.controller.handleSelection(itemIndex);
  }

  void _dispatchKeyEvent(KeyEvent e) {
    widget.controller.handleModifiers(e);
  }
}
