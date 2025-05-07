import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';

class LoomDiffingViewModel {
  final void Function(String path) onFileSelectedForCompare;
  final List<LoomDiffingItemViewModel> itemVms;
  final String comparisonFilePath;
  final String initialDirectory;

  LoomDiffingViewModel({
    required this.itemVms,
    required this.onFileSelectedForCompare,
    required this.comparisonFilePath,
    required this.initialDirectory,
  });
}
