class NavigationState {
  final String selectedMultiOutlet;

  NavigationState({required this.selectedMultiOutlet});

  NavigationState.initial() : selectedMultiOutlet = "";

  NavigationState copyWith({
    String? selectedMultiOutlet,
  }) {
    return NavigationState(
      selectedMultiOutlet: selectedMultiOutlet ?? this.selectedMultiOutlet,
    );
  }
}
