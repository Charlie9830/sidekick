import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class DiffAppStateViewModel {
  final Map<String, LoomViewModel> originalLoomViewModels;
  final void Function(String path) onFileSelectedForCompare;
  final Map<String, PowerPatchRowViewModel> originalPatchViewModels;

  DiffAppStateViewModel({
    required this.originalLoomViewModels,
    required this.onFileSelectedForCompare,
    required this.originalPatchViewModels,
  });
}
