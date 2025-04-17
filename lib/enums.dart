enum SaveType { save, saveAs }

enum LoomsDraggingState {
  idle,
  outletDragging,
}

enum CableActionModifier {
  /// Ordering is Important. The order in which they appear here will become the order in which modifications are applied,
  /// so it is important that [combineIntoSneaks] appears before [convertToPermanent]. As we want a Sneak based permanent to be
  /// selected should the user which to apply both.
  combineIntoSneaks,
  convertToPermanent,
}
