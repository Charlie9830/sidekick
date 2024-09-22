import 'dart:ui';

import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

class SetImportSettings {
  final ImportSettingsModel settings;

  SetImportSettings(this.settings);
}

class ResetFixtureState {
  ResetFixtureState();
}

class NewProject {}

class OpenProject {
  final ProjectFileModel project;
  final String parentDirectory;
  final String path;

  OpenProject(
      {required this.project,
      required this.parentDirectory,
      required this.path});
}

class SetProjectFileMetadata {
  final ProjectFileMetadataModel metadata;

  SetProjectFileMetadata(this.metadata);
}

class SetLastUsedProjectDirectory {
  final String path;

  SetLastUsedProjectDirectory(this.path);
}

class SetProjectFilePath {
  final String path;

  SetProjectFilePath(this.path);
}

class SetPatchImportFilePath {
  final String path;

  SetPatchImportFilePath(this.path);
}

class SetLooms {
  final Map<String, LoomModel> looms;

  SetLooms(this.looms);
}

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

class UpdateFixtureTypeShortName {
  final String id;
  final String newValue;

  UpdateFixtureTypeShortName(this.id, this.newValue);
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

class CommitLocationPowerPatch {
  final LocationModel location;

  CommitLocationPowerPatch(this.location);
}

class UpdateLocationName {
  final String locationId;
  final String newValue;

  UpdateLocationName(this.locationId, this.newValue);
}

class UpdateLocationColor {
  final String locationId;
  final Color newValue;

  UpdateLocationColor(this.locationId, this.newValue);
}
