int getPhaseFromIndex(int index) {
  if (index == 0) {
    return 1;
  }

  if (index == 1) {
    return 2;
  }

  if (index == 2) {
    return 3;
  }

  return _dumbSearch(index + 1);
}

int _dumbSearch(int outletNumber) {
  return _generatePhaseNumbers(outletNumber);
}

int _generatePhaseNumbers(int outletNumber) {
  int? lastPhase;
  final phases = List<int>.generate(outletNumber, (index) {
    if (lastPhase == null) {
      lastPhase = 1;
      return 1;
    }

    if (lastPhase == 1) {
      lastPhase = 2;
      return 2;
    }

    if (lastPhase == 2) {
      lastPhase = 3;
      return 3;
    }

    if (lastPhase == 3) {
      lastPhase = 1;
      return 1;
    }

    return 1;
  });

  return phases.last;
}
