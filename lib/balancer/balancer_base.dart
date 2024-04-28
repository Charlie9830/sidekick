import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

abstract class BalancerBase {
  List<PowerPatchModel> generatePatches({
    required List<FixtureModel> fixtures,
    required double maxAmpsPerCircuit,
    int maxSequenceBreak,
  });

  List<PowerOutletModel> assignToOutlets({
    required List<PowerPatchModel> patches,
    required List<PowerOutletModel> outlets,
    double imbalanceTolerance,
  });
}
