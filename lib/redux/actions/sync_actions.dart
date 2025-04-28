import 'package:excel/excel.dart';
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

class SetFixtureMappingFilePath {
  final String value;

  SetFixtureMappingFilePath(this.value);
}

class UpdateLoomName {
  final String uid;
  final String value;

  UpdateLoomName(this.uid, this.value);
}

class SetLoomStock {
  final Map<String, LoomStockModel> value;

  SetLoomStock(this.value);
}

class SetLoomsDraggingState {
  final LoomsDraggingState value;

  SetLoomsDraggingState(this.value);
}

class SetSelectedLoomOutlets {
  final Set<String> value;

  SetSelectedLoomOutlets(this.value);
}

class SetActiveImportManagerStep {
  final int value;

  SetActiveImportManagerStep(this.value);
}

class SetSelectedRawPatchRow {
  final String value;

  SetSelectedRawPatchRow(this.value);
}

class SetRawPatchData {
  final List<RawRowData> data;

  SetRawPatchData(
    this.data,
  );
}

class SetImportExcelDocument {
  final Excel document;

  SetImportExcelDocument(
    this.document,
  );
}

class SetSelectedExcelSheet {
  final String value;

  SetSelectedExcelSheet(this.value);
}

class SetExcelSheetNames {
  final Set<String> value;
  final String? selectedSheet;

  SetExcelSheetNames(this.value, this.selectedSheet);
}

class SetDiffingOriginalSource {
  final FixtureState value;

  SetDiffingOriginalSource(this.value);
}

class SetDiffingUnions {
  final Set<UnionProxy<CableModel>> cables;
  final Set<UnionProxy<LoomModel>> looms;

  SetDiffingUnions({
    required this.cables,
    required this.looms,
  });
}

class SetSelectedDiffingTab {
  final int value;

  SetSelectedDiffingTab(
    this.value,
  );
}

class SetOpenAfterExport {
  final bool value;

  SetOpenAfterExport(this.value);
}

class UpdateProjectName {
  final String newValue;

  UpdateProjectName(this.newValue);
}

class SetLastUsedExportDirectory {
  final String value;

  SetLastUsedExportDirectory(this.value);
}

class SetDefaultPowerMulti {
  final CableType value;

  SetDefaultPowerMulti(this.value);
}

class UpdateCableLength {
  final String uid;
  final String newLength;

  UpdateCableLength(this.uid, this.newLength);
}

class UpdateCablesAndDataMultis {
  final Map<String, CableModel> cables;
  final Map<String, DataMultiModel> dataMultis;

  UpdateCablesAndDataMultis(
    this.cables,
    this.dataMultis,
  );
}

class ToggleCableDropperStateByLoom {
  final String loomId;

  ToggleCableDropperStateByLoom(this.loomId);
}

class SetCablesAndLooms {
  final Map<String, CableModel> cables;
  final Map<String, LoomModel> looms;

  SetCablesAndLooms(this.cables, this.looms);
}

class SetIsAvailabilityDrawerOpen {
  final bool value;

  SetIsAvailabilityDrawerOpen(this.value);
}

class UpdateCableNote {
  final String id;
  final String value;

  UpdateCableNote(this.id, this.value);
}

class UpdateLoomLength {
  final String id;
  final String newValue;

  UpdateLoomLength(this.id, this.newValue);
}

class SetCables {
  final Map<String, CableModel> cables;

  SetCables(this.cables);
}

class SetSelectedCableIds {
  final Set<String> ids;

  SetSelectedCableIds(this.ids);
}

class SetLocationPowerLock {
  final String locationId;
  final bool value;

  SetLocationPowerLock(this.locationId, this.value);
}

class SetLocationDataLock {
  final String locationId;
  final bool value;

  SetLocationDataLock(this.locationId, this.value);
}

class SetHonorDataSpans {
  final bool value;

  SetHonorDataSpans(this.value);
}

class SetShowAllFixtureTypes {
  final bool value;

  SetShowAllFixtureTypes(this.value);
}

class SetFixtureTypes {
  final Map<String, FixtureTypeModel> types;

  SetFixtureTypes(this.types);
}

class SetIsFixtureTypeDatabasePathValid {
  final bool value;

  SetIsFixtureTypeDatabasePathValid(this.value);
}

class SetFixtureTypeDatabasePath {
  final String path;

  SetFixtureTypeDatabasePath(this.path);
}

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

class UpdateLocationDelimiter {
  final String locationId;
  final String newValue;

  UpdateLocationDelimiter(this.locationId, this.newValue);
}

class UpdateLocationColor {
  final String locationId;
  final LabelColorModel newValue;

  UpdateLocationColor(this.locationId, this.newValue);
}
