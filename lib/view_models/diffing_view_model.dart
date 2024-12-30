class DiffingViewModel {
  final int selectedTab;
  final void Function(int value) onDiffingTabChanged;

  DiffingViewModel({
    required this.selectedTab,
    required this.onDiffingTabChanged,
  });
}
