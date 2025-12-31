import 'package:sidekick/view_models/fixture_diffing_item_view_model.dart';
import 'package:sidekick/view_models/hoist_controller_diffing_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/patch_diffing_item_view_model.dart';

class DiffingScreenViewModel {
  final void Function(String path) onFileSelectedForCompare;
  final List<LoomDiffingItemViewModel> loomItemVms;
  final List<PatchDiffingItemViewModel> patchItemVms;
  final List<FixtureDiffingItemViewModel> fixtureItemVms;
  final String comparisonFilePath;
  final String initialDirectory;
  final List<HoistControllerDiffingViewModel> hoistControllerVms;
  final void Function(int index) onTabSelected;
  final int selectedTab;

  DiffingScreenViewModel({
    required this.loomItemVms,
    required this.patchItemVms,
    required this.onFileSelectedForCompare,
    required this.comparisonFilePath,
    required this.initialDirectory,
    required this.fixtureItemVms,
    required this.hoistControllerVms,
    required this.onTabSelected,
    required this.selectedTab,
  });
}
