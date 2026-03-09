class HomeViewModel {
  final Set<String> selectedFixtureIds;
  final void Function() onDebugAction;
  final void Function() onAppInitialize;
  final void Function(Set<String> ids) onSelectedFixturesChanged;
  final void Function() onSetSequenceButtonPressed;
  final int racksTabIndex;
  final void Function(int index) onRacksTabIndexChanged;

  HomeViewModel({
    required this.onDebugAction,
    required this.onAppInitialize,
    required this.selectedFixtureIds,
    required this.onSelectedFixturesChanged,
    required this.onSetSequenceButtonPressed,
    required this.onRacksTabIndexChanged,
    required this.racksTabIndex,
  });
}
