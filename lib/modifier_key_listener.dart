import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/modifier_key_provider.dart';

/// When inserted in the Widget Hierachy this widget will listen for changes to Keyboard Modifier keys.
/// It provides an inheriated widget [ModifierKeyMessenger] which provides the current state of Modifier Keys
/// to decendant widgets.
class ModifierKeyProvider extends StatelessWidget {
  final Widget child;
  const ModifierKeyProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ModifierKeyChangeBuilder(builder: (context, keysDown) {
      return ModifierKeyMessenger(
        keysDown: keysDown,
        child: child,
      );
    });
  }
}

class ModifierKeyMessenger extends InheritedWidget {
  final Set<LogicalKeyboardKey> keysDown;
  const ModifierKeyMessenger({
    super.key,
    required Widget child,
    required this.keysDown,
  }) : super(child: child);

  static ModifierKeyMessenger? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModifierKeyMessenger>();
  }

  @override
  bool updateShouldNotify(ModifierKeyMessenger oldWidget) {
    return oldWidget.keysDown != keysDown;
  }
}
