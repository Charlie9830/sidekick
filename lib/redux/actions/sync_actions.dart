import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class SetFixtures {
  final Map<String, FixtureModel> fixtures;
  SetFixtures(this.fixtures);
}

class SetLocations {
  final Map<String, LocationModel> locations;
  SetLocations(this.locations);
}

class SetPowerPatches {
  final List<PowerPatchModel> patches;

  SetPowerPatches(this.patches);
}

class SetPowerMultiOutlets {
  final Map<String, PowerMultiOutletModel> multiOutlets;

  SetPowerMultiOutlets(this.multiOutlets);
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

class UpdateLocationMultiPrefix {
  final String location;
  final String newValue;

  UpdateLocationMultiPrefix(this.location, this.newValue);
}

class CommitLocationPowerPatch {
  final LocationModel location;

  CommitLocationPowerPatch(this.location);
}
