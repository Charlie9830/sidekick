class HomeViewModel {
  final Set<String> selectedFixtureIds;
  final void Function() onDebugAction;
  final void Function() onAppInitialize;
  final void Function(Set<String> ids) onSelectedFixturesChanged;
  final void Function() onSetSequenceButtonPressed;

  HomeViewModel({
    required this.onDebugAction,
    required this.onAppInitialize,
    required this.selectedFixtureIds,
    required this.onSelectedFixturesChanged,
    required this.onSetSequenceButtonPressed,
  });
}
