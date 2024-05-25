class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
  });

  NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = {};

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
    );
  }
}
