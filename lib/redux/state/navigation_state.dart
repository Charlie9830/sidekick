class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;
  final bool showAllFixtureTypes;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
    required this.showAllFixtureTypes,
  });

  NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = {},
        showAllFixtureTypes = false;

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
    bool? showAllFixtureTypes,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
      showAllFixtureTypes: showAllFixtureTypes ?? this.showAllFixtureTypes,
    );
  }
}
