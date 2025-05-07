import 'package:sidekick/view_models/loom_view_model.dart';

class DiffAppStateViewModel {
  final Map<String, LoomViewModel> originalLoomViewModels;
  final void Function(String path) onFileSelectedForCompare;

  DiffAppStateViewModel({
    required this.originalLoomViewModels,
    required this.onFileSelectedForCompare,
  });
}
