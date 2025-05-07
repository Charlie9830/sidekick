import 'package:sidekick/containers/looms_diffing_container.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

class LoomDiffingItemViewModel {
  final LoomViewModel? current;
  final LoomViewModel? original;
  final Map<String, CableDelta> cableDeltas;
  final DiffState overallDiff;

  final Set<PropertyDelta> deltas;

  LoomDiffingItemViewModel({
    required this.current,
    required this.original,
    required this.deltas,
    required this.overallDiff,
    required this.cableDeltas,
  });
}
