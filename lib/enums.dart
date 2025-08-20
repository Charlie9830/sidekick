enum SaveType { save, saveAs }

enum LoomsDraggingState {
  idle,
  outletDragging,
}

enum ImportManagerStep {
  fileSelect(0),
  fixtureMapping(1),
  viewData(2),
  mergeData(3);

  final int stepNumber;
  const ImportManagerStep(this.stepNumber);

  static Map<int, ImportManagerStep> byStepNumber = {
    ImportManagerStep.fileSelect.stepNumber: ImportManagerStep.fileSelect,
    ImportManagerStep.fixtureMapping.stepNumber:
        ImportManagerStep.fixtureMapping,
    ImportManagerStep.viewData.stepNumber: ImportManagerStep.viewData,
    ImportManagerStep.mergeData.stepNumber: ImportManagerStep.mergeData,
  };
}

enum CableActionModifier {
  /// Ordering is Important. The order in which they appear here will become the order in which modifications are applied,
  /// so it is important that [combineIntoMultis] appears before [convertToPermanent]. As we want a Sneak based permanent to be
  /// selected should the user which to apply both.
  combineIntoMultis,
  convertToPermanent,
}
