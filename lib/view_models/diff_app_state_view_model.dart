import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class DiffAppStateViewModel {
  final Map<String, LoomViewModel> originalLoomViewModels;
  final void Function(String path) onFileSelectedForCompare;
  final Map<String, PowerPatchRowViewModel> originalPatchViewModels;
  final Map<String, FixtureTableRowViewModel> originalFixtureViewModels;

  DiffAppStateViewModel({
    required this.originalLoomViewModels,
    required this.onFileSelectedForCompare,
    required this.originalPatchViewModels,
    required this.originalFixtureViewModels,
  });
}
