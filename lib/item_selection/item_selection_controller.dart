import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/extension_methods/add_if_absent_else_remove.dart';

class ItemSelectionController extends ChangeNotifier {
  bool _isModDown = false;
  bool _isShiftDown = false;
  Set<int> _selectedItems = {};

  Set<int> get selectedItems => _selectedItems;

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

  void handleSelection(int index) {
    if (_isModDown && _isShiftDown) {
      return;
    }

    if (_isModDown) {
      _handleModDownSelection(index);
      return;
    }

    if (_isShiftDown) {
      _handleShiftDownSelection(index);
      return;
    }

    _handleCommonSelection(index);
  }

  void _handleShiftDownSelection(int index) {
    if (_selectedItems.isEmpty) {
      _handleCommonSelection(index);
      return;
    }

    final [int lower, int upper] = [_selectedItems.first, index]..sort();
    final diff = upper - lower;

    final range = [
      ...List<int>.generate(diff, (baseIndex) => baseIndex + lower),
      upper
    ];
    final updatedItems = _selectedItems.toSet()..addAll(range);

    _selectedItems = updatedItems;
    notifyListeners();
  }

  void _handleCommonSelection(int index) {
    _selectedItems = {index};
    notifyListeners();
  }

  void _handleModDownSelection(int index) {
    final updatedItems = _selectedItems.toSet()..addIfAbsentElseRemove(index);
    _selectedItems = updatedItems;
    notifyListeners();
  }
}
