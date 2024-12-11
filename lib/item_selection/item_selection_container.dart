import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

enum UpdateType {
  overwrite,
  addIfAbsentElseRemove,
}

class ItemSelectionContainer<T> extends StatefulWidget {
  final Widget child;
  final Set<T> selectedItems;
  final Map<T, int> itemIndicies;
  final void Function(UpdateType updateType, Set<T> values) onSelectionUpdated;

  const ItemSelectionContainer({
    super.key,
    required this.child,
    required this.selectedItems,
    required this.itemIndicies,
    required this.onSelectionUpdated,
  });

  @override
  State<ItemSelectionContainer<T>> createState() =>
      _ItemSelectionContainerState<T>();
}

class _ItemSelectionContainerState<T> extends State<ItemSelectionContainer<T>> {
  late final FocusNode _keyboardFocusNode;
  bool _isModDown = false;
  bool _isShiftDown = false;

  @override
  void initState() {
    _keyboardFocusNode = FocusNode();
    _keyboardFocusNode.requestFocus();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ItemSelectionMessenger<T>(
      onItemPointerUp: _handleItemPointerUp,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _dispatchKeyEvent,
        child: widget.child,
      ),
    );
  }

  void _handleSelection(T value) {
    if (_isModDown && _isShiftDown) {
      return;
    }

    if (_isModDown) {
      _handleModDownSelection(value);
      return;
    }

    if (_isShiftDown) {
      _handleShiftDownSelection(value);
      return;
    }

    _handleCommonSelection(value);
  }

  void _handleShiftDownSelection(T value) {
    if (widget.selectedItems.isEmpty) {
      _handleCommonSelection(value);
      return;
    }

    final [int lower, int upper] = [
      widget.itemIndicies[widget.selectedItems.first] ?? 0,
      widget.itemIndicies[value] ?? 0
    ]..sort();
    final diff = upper - lower;

    final selectionRange = [
      ...List<int>.generate(diff, (baseIndex) => baseIndex + lower),
      upper
    ];

    final inverseLookup = Map<int, T>.fromEntries(widget.itemIndicies.entries
        .map((entry) => MapEntry(entry.value, entry.key)));

    final updatedItems = selectionRange
        .map((index) => inverseLookup[index])
        .where((item) => item != null)
        .cast<T>()
        .toSet();

    widget.onSelectionUpdated(UpdateType.overwrite, updatedItems);
  }

  void _handleCommonSelection(T value) {
    widget.onSelectionUpdated(UpdateType.overwrite, {value});
  }

  void _handleModDownSelection(T value) {
    widget.onSelectionUpdated(UpdateType.addIfAbsentElseRemove, {value});
  }

  void _handleModifiers(KeyEvent e) {
    if (e is KeyRepeatEvent) {
      return;
    }

    final (modTouched, shiftTouched) = _extractModifiers(e);

    bool? modDown;
    if (modTouched == true) {
      modDown = e is KeyDownEvent ? true : false;
    }

    bool? shiftDown;
    if (shiftTouched == true) {
      shiftDown = e is KeyDownEvent ? true : false;
    }

    final concreteModDown = modDown ?? _isModDown;
    final concreteShiftDown = shiftDown ?? _isShiftDown;

    setState(() {
      _isModDown = concreteModDown;
      _isShiftDown = concreteShiftDown;
    });
  }

  void _handleItemPointerUp(PointerUpEvent e, T value) {
    _handleSelection(value);
  }

  void _dispatchKeyEvent(KeyEvent e) {
    _handleModifiers(e);
  }

  ///
  /// Returns a boolean tuple that signals if a Mod Key has been touched and/or a shift key has been touched.
  /// This method can be called as a result of a [KeyDown], [KeyUp], [KeySignal] or [KeyRepeat] event. Therefore
  /// we don't specify whether Mod or Shift is down, only if it has been touched, as it could be a [KeyUp] event
  /// triggering this function, which in that case the Key is up and no longer down.
  ///
  (bool modTouched, bool shiftTouched) _extractModifiers(KeyEvent e) {
    return (
      // Ctrl
      e.logicalKey == LogicalKeyboardKey.controlLeft ||
          e.logicalKey == LogicalKeyboardKey.controlRight,

      // Shift
      e.logicalKey == LogicalKeyboardKey.shiftLeft ||
          e.logicalKey == LogicalKeyboardKey.shiftRight,
    );
  }
}
