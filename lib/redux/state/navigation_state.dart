// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/enums.dart';

class NavigationState {
  final String selectedMultiOutlet;
  final Set<String> selectedFixtureIds;
  final bool showAllFixtureTypes;
  final Set<String> selectedCableIds;
  final bool openAfterExport;
  final int selectedDiffingTab;
  final ImportManagerStep importManagerStep;
  final Set<String> selectedLoomOutlets;
  final LoomsDraggingState loomsDraggingState;
  final bool isAvailabilityDrawerOpen;
  final Set<String> selectedHoistIds;
  final Set<String> selectedHoistChannelIds;

  NavigationState({
    required this.selectedMultiOutlet,
    required this.selectedFixtureIds,
    required this.showAllFixtureTypes,
    required this.selectedCableIds,
    required this.openAfterExport,
    required this.selectedDiffingTab,
    required this.importManagerStep,
    required this.selectedLoomOutlets,
    required this.loomsDraggingState,
    required this.isAvailabilityDrawerOpen,
    required this.selectedHoistIds,
    required this.selectedHoistChannelIds,
  });

  const NavigationState.initial()
      : selectedMultiOutlet = "",
        selectedFixtureIds = const {},
        selectedCableIds = const {},
        showAllFixtureTypes = false,
        openAfterExport = true,
        selectedDiffingTab = 0,
        importManagerStep = ImportManagerStep.fileSelect,
        selectedLoomOutlets = const {},
        loomsDraggingState = LoomsDraggingState.idle,
        isAvailabilityDrawerOpen = false,
        selectedHoistIds = const {},
        selectedHoistChannelIds = const {};

  NavigationState copyWith({
    String? selectedMultiOutlet,
    Set<String>? selectedFixtureIds,
    bool? showAllFixtureTypes,
    Set<String>? selectedCableIds,
    bool? openAfterExport,
    int? selectedDiffingTab,
    ImportManagerStep? importManagerStep,
    Set<String>? selectedLoomOutlets,
    LoomsDraggingState? loomsDraggingState,
    bool? isAvailabilityDrawerOpen,
    Set<String>? selectedHoistIds,
    Set<String>? selectedHoistChannelIds,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
      selectedFixtureIds: selectedFixtureIds ?? this.selectedFixtureIds,
      showAllFixtureTypes: showAllFixtureTypes ?? this.showAllFixtureTypes,
      selectedCableIds: selectedCableIds ?? this.selectedCableIds,
      openAfterExport: openAfterExport ?? this.openAfterExport,
      selectedDiffingTab: selectedDiffingTab ?? this.selectedDiffingTab,
      importManagerStep: importManagerStep ?? this.importManagerStep,
      selectedLoomOutlets: selectedLoomOutlets ?? this.selectedLoomOutlets,
      loomsDraggingState: loomsDraggingState ?? this.loomsDraggingState,
      isAvailabilityDrawerOpen:
          isAvailabilityDrawerOpen ?? this.isAvailabilityDrawerOpen,
      selectedHoistIds: selectedHoistIds ?? this.selectedHoistIds,
      selectedHoistChannelIds:
          selectedHoistChannelIds ?? this.selectedHoistChannelIds,
    );
  }
}
