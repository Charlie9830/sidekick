import 'package:flutter/services.dart';
import 'package:sidekick/enums.dart';

Set<CableActionModifier> mapCableActionModifierKeys(
    Set<LogicalKeyboardKey> keysDown) {
  return {
    if (keysDown.contains(LogicalKeyboardKey.shiftLeft))
      CableActionModifier.combineIntoSneaks,
    if (keysDown.contains(LogicalKeyboardKey.controlLeft))
      CableActionModifier.convertToPermanent
  };
}
