import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class SetFixtures {
  final Map<String, FixtureModel> fixtures;
  SetFixtures(this.fixtures);
}

class SetPowerPatches {
  final List<PowerPatchModel> patches;

  SetPowerPatches(this.patches);
}

class SetPowerOutlets {
  final List<PowerOutletModel> outlets;

  SetPowerOutlets(this.outlets);
}

class SelectPatchRow {
  final String uid;

  SelectPatchRow(this.uid);
}

class SetBalanceTolerance {
  final String value;

  SetBalanceTolerance(this.value);
}

class SetMaxSequenceBreak {
  final String value;

  SetMaxSequenceBreak(this.value);
}
