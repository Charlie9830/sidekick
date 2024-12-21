class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;
  final bool showAllFixtureTypes;
  final Set<String> selectedCableIds;
  final bool openAfterExport;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
    required this.showAllFixtureTypes,
    required this.selectedCableIds,
    required this.openAfterExport,
  });

  NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = {},
        selectedCableIds = {},
        showAllFixtureTypes = false,
        openAfterExport = true;

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
    bool? showAllFixtureTypes,
    Set<String>? selectedCableIds,
    bool? openAfterExport,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
      showAllFixtureTypes: showAllFixtureTypes ?? this.showAllFixtureTypes,
      selectedCableIds: selectedCableIds ?? this.selectedCableIds,
      openAfterExport: openAfterExport ?? this.openAfterExport,
    );
  }
}
