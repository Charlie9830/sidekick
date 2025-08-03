import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef KeyChangeBuilder = Widget Function(
    BuildContext context, Set<LogicalKeyboardKey> downKeys);

class KeyboardChangeBuilder extends StatefulWidget {
  final KeyChangeBuilder builder;
  final Set<LogicalKeyboardKey> listenFor;

  const KeyboardChangeBuilder({
    super.key,
    required this.builder,
    required this.listenFor,
  });

  @override
  State<KeyboardChangeBuilder> createState() => _KeyboardChangeBuilderState();
}

class _KeyboardChangeBuilderState extends State<KeyboardChangeBuilder> {
  Set<LogicalKeyboardKey> _downKeys = {};

  @override
  void initState() {
    super.initState();

    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _downKeys);
  }

  bool _handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent && widget.listenFor.contains(e.logicalKey)) {
      setState(() {
        _downKeys = _downKeys.toSet()..add(e.logicalKey);
      });
    }

    if (e is KeyUpEvent && _downKeys.contains(e.logicalKey)) {
      setState(() {
        _downKeys = _downKeys.toSet()..remove(e.logicalKey);
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
