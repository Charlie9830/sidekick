enum SaveType { save, saveAs }

enum LoomsDraggingState {
  idle,
  outletDragging,
}

enum ImportManagerStep {
  fileSelect(1),
  fixtureMapping(2),
  viewData(3);

  final int stepNumber;
  const ImportManagerStep(this.stepNumber);

  static Map<int, ImportManagerStep> byStepNumber = {
    ImportManagerStep.fileSelect.stepNumber: ImportManagerStep.fileSelect,
    ImportManagerStep.fixtureMapping.stepNumber:
        ImportManagerStep.fixtureMapping,
    ImportManagerStep.viewData.stepNumber: ImportManagerStep.viewData,
  };
}

enum CableActionModifier {
  /// Ordering is Important. The order in which they appear here will become the order in which modifications are applied,
  /// so it is important that [combineIntoSneaks] appears before [convertToPermanent]. As we want a Sneak based permanent to be
  /// selected should the user which to apply both.
  combineIntoSneaks,
  convertToPermanent,
}
