import 'package:sidekick/view_models/fixture_diffing_item_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/patch_diffing_item_view_model.dart';

class DiffingScreenViewModel {
  final void Function(String path) onFileSelectedForCompare;
  final List<LoomDiffingItemViewModel> loomItemVms;
  final List<PatchDiffingItemViewModel> patchItemVms;
  final List<FixtureDiffingItemViewModel> fixtureItemVms;
  final String comparisonFilePath;
  final String initialDirectory;

  DiffingScreenViewModel({
    required this.loomItemVms,
    required this.patchItemVms,
    required this.onFileSelectedForCompare,
    required this.comparisonFilePath,
    required this.initialDirectory,
    required this.fixtureItemVms,
  });
}
