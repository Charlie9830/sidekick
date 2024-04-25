class PhaseCounter {
  int _currentPhase = 0;

  int get nextPhase {
    if (_currentPhase == 3) {
      _currentPhase = 1;
      return 1;
    }

    return ++_currentPhase;
  }
}
