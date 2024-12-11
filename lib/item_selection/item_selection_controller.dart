import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum UpdateType {
  overwrite,
  addIfAbsentElseRemove,
}

class ItemSelectionController extends ChangeNotifier {
  bool _isModDown = false;
  bool _isShiftDown = false;

  final void Function(UpdateType updateType, Set<Object> values)
      onUpdateSelection;

  Set<Object> currentlySelectedValues;
  Map<Object, int> itemIndices;

  ItemSelectionController({
    required this.onUpdateSelection,
    required this.currentlySelectedValues,
    required this.itemIndices,
  });

  set isModDown(bool value) {
    _isModDown = value;
    notifyListeners();
  }

  bool get isModDown => _isModDown;

  set isShiftDown(bool value) {
    _isShiftDown = value;
    notifyListeners();
  }

  bool get isShiftDown => _isShiftDown;

  void handleModifiers(KeyEvent e) {
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

    _isModDown = modDown ?? _isModDown;
    _isShiftDown = shiftDown ?? _isShiftDown;
    notifyListeners();
  }

  (bool modPressed, bool shiftPressed) _extractModifiers(KeyEvent e) {
    return (
      // Ctrl
      e.logicalKey == LogicalKeyboardKey.controlLeft ||
          e.logicalKey == LogicalKeyboardKey.controlRight,

      // Shift
      e.logicalKey == LogicalKeyboardKey.shiftLeft ||
          e.logicalKey == LogicalKeyboardKey.shiftRight,
    );
  }

  void handleSelection(Object value) {
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

  void _handleShiftDownSelection(Object value) {
    if (currentlySelectedValues.isEmpty) {
      _handleCommonSelection(value);
      return;
    }

    final [int lower, int upper] = [
      itemIndices[currentlySelectedValues.first] ?? 0,
      itemIndices[value] ?? 0
    ]..sort();
    final diff = upper - lower;

    final selectionRange = [
      ...List<int>.generate(diff, (baseIndex) => baseIndex + lower),
      upper
    ];

    final inverseLookup = Map<int, Object>.fromEntries(
        itemIndices.entries.map((entry) => MapEntry(entry.value, entry.key)));

    final updatedItems =
        selectionRange.map((index) => inverseLookup[index]).nonNulls.toSet();

    onUpdateSelection(UpdateType.overwrite, updatedItems);
  }

  void _handleCommonSelection(Object value) {
    onUpdateSelection(UpdateType.overwrite, {value});
  }

  void _handleModDownSelection(Object value) {
    onUpdateSelection(UpdateType.addIfAbsentElseRemove, {value});
  }
}
