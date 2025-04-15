import 'package:flutter/services.dart';
import 'package:sidekick/enums.dart';

CableActionModifier mapCableActionModifierKeys(
    Set<LogicalKeyboardKey> keysDown) {
  if (keysDown.contains(LogicalKeyboardKey.shiftLeft)) {
    return CableActionModifier.combineIntoSneaks;
  }

  return CableActionModifier.none;
}
