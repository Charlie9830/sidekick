import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class PatchDiffingItemViewModel {
  final PowerPatchRowViewModel? current;
  final PowerPatchRowViewModel? original;
  final DiffState overallDiff;
  final List<OutletDelta> outletDeltas;

  final PropertyDeltaSet deltas;

  PatchDiffingItemViewModel({
    required this.current,
    required this.original,
    required this.deltas,
    required this.overallDiff,
    this.outletDeltas = const []
  });
}
