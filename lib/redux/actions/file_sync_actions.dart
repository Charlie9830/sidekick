import 'package:excel_community/excel_community.dart';
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

class SetComparisonFilePath {
  final String value;

  SetComparisonFilePath(this.value);
}

class SetFixtureMappingFilePath {
  final String value;

  SetFixtureMappingFilePath(this.value);
}

class SetImportedFixtureData {
  Map<String, FixtureModel> fixtures;
  Map<String, LocationModel> locations;
  Map<String, FixtureTypeModel> fixtureTypes;
  Map<String, TrussModel> trusses;
  Map<String, FixtureGeometryModel> fixtureGeometries;

  SetImportedFixtureData({
    required this.fixtures,
    required this.locations,
    required this.fixtureTypes,
    required this.trusses,
    required this.fixtureGeometries,
  });
}

class SetImportManagerStep {
  final ImportManagerStep value;

  SetImportManagerStep(this.value);
}

class SetImportExcelDocument {
  final Excel document;

  SetImportExcelDocument(this.document);
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

  SetDiffingUnions({required this.cables, required this.looms});
}

class SetSelectedDiffingTab {
  final int value;

  SetSelectedDiffingTab(this.value);
}

class UpdateProjectName {
  final String newValue;

  UpdateProjectName(this.newValue);
}

class SetIsFixtureTypeDatabasePathValid {
  final bool value;

  SetIsFixtureTypeDatabasePathValid(this.value);
}

class SetFixtureTypeDatabasePath {
  final String path;

  SetFixtureTypeDatabasePath(this.path);
}

class ResetFixtureState {
  ResetFixtureState();
}

/// Flags whether the project holds edits that have not been written to disk.
///
/// Dispatched by `unsavedChangesMiddleware` when project content changes. The
/// flag is cleared by the reducer on [NewProject], [OpenProject] and
/// [SetProjectFileMetadata], each of which establishes a clean baseline.
class SetHasUnsavedChanges {
  final bool value;

  SetHasUnsavedChanges(this.value);
}

class NewProject {}

class OpenProject {
  final ProjectFileModel project;
  final String parentDirectory;
  final String path;

  OpenProject({
    required this.project,
    required this.parentDirectory,
    required this.path,
  });
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
