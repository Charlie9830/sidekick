// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/enums.dart';

class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;
  final bool showAllFixtureTypes;
  final Set<String> selectedCableIds;
  final bool openAfterExport;
  final int selectedDiffingTab;
  final String selectedRawPatchRow;
  final int activeImportManagerStep;
  final Set<String> selectedLoomOutlets;
  final LoomsDraggingState loomsDraggingState;
  final bool isAvailabilityDrawerOpen;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
    required this.showAllFixtureTypes,
    required this.selectedCableIds,
    required this.openAfterExport,
    required this.selectedDiffingTab,
    required this.selectedRawPatchRow,
    required this.activeImportManagerStep,
    required this.selectedLoomOutlets,
    required this.loomsDraggingState,
    required this.isAvailabilityDrawerOpen,
  });

  NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = {},
        selectedCableIds = {},
        showAllFixtureTypes = false,
        openAfterExport = true,
        selectedDiffingTab = 0,
        selectedRawPatchRow = '',
        activeImportManagerStep = 1,
        selectedLoomOutlets = {},
        loomsDraggingState = LoomsDraggingState.idle,
        isAvailabilityDrawerOpen = false;

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
    bool? showAllFixtureTypes,
    Set<String>? selectedCableIds,
    bool? openAfterExport,
    int? selectedDiffingTab,
    String? selectedRawPatchRow,
    int? activeImportManagerStep,
    Set<String>? selectedLoomOutlets,
    LoomsDraggingState? loomsDraggingState,
    bool? isAvailabilityDrawerOpen,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
      showAllFixtureTypes: showAllFixtureTypes ?? this.showAllFixtureTypes,
      selectedCableIds: selectedCableIds ?? this.selectedCableIds,
      openAfterExport: openAfterExport ?? this.openAfterExport,
      selectedDiffingTab: selectedDiffingTab ?? this.selectedDiffingTab,
      selectedRawPatchRow: selectedRawPatchRow ?? this.selectedRawPatchRow,
      activeImportManagerStep:
          activeImportManagerStep ?? this.activeImportManagerStep,
      selectedLoomOutlets: selectedLoomOutlets ?? this.selectedLoomOutlets,
      loomsDraggingState: loomsDraggingState ?? this.loomsDraggingState,
      isAvailabilityDrawerOpen:
          isAvailabilityDrawerOpen ?? this.isAvailabilityDrawerOpen,
    );
  }
}
