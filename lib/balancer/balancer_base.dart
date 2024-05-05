import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

abstract class Balancer {
  ///
  /// Generates a Map of [PowerPatchModel] objects keyed by their parent [LocationModel] uids.
  ///
  Map<String, List<PowerPatchModel>> generatePatches({
    required List<FixtureModel> fixtures,
    required double maxAmpsPerCircuit,
    int maxSequenceBreak,
  });

  Map<String, List<PowerOutletModel>> assignToOutlets({
    required Map<String, List<PowerPatchModel>> patchesByLocationId,
    required List<PowerOutletModel> outlets,
    double imbalanceTolerance,
  });
}
