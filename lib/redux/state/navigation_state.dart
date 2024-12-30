class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;
  final bool showAllFixtureTypes;
  final Set<String> selectedCableIds;
  final bool openAfterExport;
  final int selectedDiffingTab;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
    required this.showAllFixtureTypes,
    required this.selectedCableIds,
    required this.openAfterExport,
    required this.selectedDiffingTab,
  });

  NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = {},
        selectedCableIds = {},
        showAllFixtureTypes = false,
        openAfterExport = true,
        selectedDiffingTab = 0;

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
    bool? showAllFixtureTypes,
    Set<String>? selectedCableIds,
    bool? openAfterExport,
    int? selectedDiffingTab,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
      showAllFixtureTypes: showAllFixtureTypes ?? this.showAllFixtureTypes,
      selectedCableIds: selectedCableIds ?? this.selectedCableIds,
      openAfterExport: openAfterExport ?? this.openAfterExport,
      selectedDiffingTab: selectedDiffingTab ?? this.selectedDiffingTab,
    );
  }
}
