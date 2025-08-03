import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/keyboard_change_builder.dart';

class ModifierKeyChangeBuilder extends StatelessWidget {
  final KeyChangeBuilder builder;
  ModifierKeyChangeBuilder({
    super.key,
    required this.builder,
  });

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

  @override
  Widget build(BuildContext context) {
    return KeyboardChangeBuilder(builder: builder, listenFor: _modifierKeys);
  }
}
