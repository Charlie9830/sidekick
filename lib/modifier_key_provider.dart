import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef KeyChangeBuilder = Widget Function(
    BuildContext context, Set<LogicalKeyboardKey> downKeys);

class ModifierKeyChangeBuilder extends StatefulWidget {
  final KeyChangeBuilder builder;
  const ModifierKeyChangeBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ModifierKeyChangeBuilder> createState() =>
      _ModifierKeyChangeBuilderState();
}

final Set<LogicalKeyboardKey> _modifierKeys = {
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
};

class _ModifierKeyChangeBuilderState extends State<ModifierKeyChangeBuilder> {
  Set<LogicalKeyboardKey> _downModifierKeys = {};

  @override
  void initState() {
    super.initState();

    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _downModifierKeys);
  }

  bool _handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent && _modifierKeys.contains(e.logicalKey)) {
      setState(() {
        _downModifierKeys = _downModifierKeys.toSet()..add(e.logicalKey);
      });
    }

    if (e is KeyUpEvent && _modifierKeys.contains(e.logicalKey)) {
      setState(() {
        _downModifierKeys = _downModifierKeys.toSet()..remove(e.logicalKey);
      });
    }

    return false;
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    super.dispose();
  }
}
