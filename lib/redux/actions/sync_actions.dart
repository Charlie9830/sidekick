import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class UpdateFixtureTypeMaxPiggybacks {
  final String id;
  final String newValue;

  UpdateFixtureTypeMaxPiggybacks(this.id, this.newValue);
}

class UpdateFixtureTypeName {
  final String id;
  final String newValue;

  UpdateFixtureTypeName(this.id, this.newValue);
}

class SetSelectedFixtureIds {
  final Set<String> ids;

  SetSelectedFixtureIds(this.ids);
}

class SetDataPatches {
  final Map<String, DataPatchModel> patches;

  SetDataPatches(this.patches);
}

class SetDataMultis {
  final Map<String, DataMultiModel> multis;

  SetDataMultis(this.multis);
}

class SetSelectedMultiOutlet {
  final String uid;

  SetSelectedMultiOutlet(this.uid);
}

class SetFixtures {
  final Map<String, FixtureModel> fixtures;
  SetFixtures(this.fixtures);
}

class SetLocations {
  final Map<String, LocationModel> locations;
  SetLocations(this.locations);
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
  final String locationId;
  final String newValue;

  UpdateLocationMultiPrefix(this.locationId, this.newValue);
}

class CommitLocationPowerPatch {
  final LocationModel location;

  CommitLocationPowerPatch(this.location);
}

class UpdateLocationName {
  final String locationId;
  final String newValue;

  UpdateLocationName(this.locationId, this.newValue);
}
