import 'package:collection/collection.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/file_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:path/path.dart' as p;

FileState fileStateReducer(FileState state, dynamic a) {
  if (a is SetIsValidatingExportData) {
    return state.copyWith(isValidatingExportData: a.value);
  }
  if (a is SetExportErrors) {
    return state.copyWith(
      isValidatingExportData: false,
      exportErrors: a.errors.sorted((a, b) => b.level.index - a.level.index),
    );
  }

  if (a is SetHasUnsavedChanges) {
    return state.copyWith(hasUnsavedChanges: a.value);
  }

  if (a is NewProject) {
    return state.copyWith(
      fixturePatchImportPath: '',
      projectFilePath: '',
      projectMetadata: const ProjectFileMetadataModel.initial(),
      comparisonFilePath: '',
      hasUnsavedChanges: false,
    );
  }

  if (a is SetComparisonFilePath) {
    return state.copyWith(comparisonFilePath: a.value);
  }

  if (a is UpdateProjectName) {
    return state.copyWith(
      projectMetadata: state.projectMetadata.copyWith(
        projectName: a.newValue.trim(),
      ),
    );
  }

  if (a is SetLastUsedExportDirectory) {
    return state.copyWith(
      projectMetadata: state.projectMetadata.copyWith(
        lastUsedExportDirectory: a.value.trim(),
      ),
    );
  }

  if (a is SetIsFixtureTypeDatabasePathValid) {
    return state.copyWith(isFixtureTypeDatabasePathValid: a.value);
  }

  if (a is SetFixtureTypeDatabasePath) {
    return state.copyWith(fixtureTypeDatabasePath: a.path);
  }

  if (a is SetFixtureMappingFilePath) {
    return state.copyWith(fixtureMappingFilePath: a.value);
  }

  if (a is SetPatchImportFilePath) {
    return state.copyWith(fixturePatchImportPath: a.path);
  }

  if (a is SetProjectFilePath) {
    return state.copyWith(
      projectFilePath: a.path,
      projectMetadata: state.projectMetadata.copyWith(
        projectName: p.basenameWithoutExtension(a.path),
      ),
    );
  }

  if (a is SetLastUsedProjectDirectory) {
    return state.copyWith(lastUsedProjectDirectory: a.path);
  }

  if (a is SetProjectFileMetadata) {
    // Only dispatched once a save has written successfully, so it is the
    // natural point at which the project becomes clean again.
    return state.copyWith(
      projectMetadata: a.metadata,
      hasUnsavedChanges: false,
    );
  }

  if (a is OpenProject) {
    return state.copyWith(
      lastUsedProjectDirectory: a.parentDirectory,
      projectMetadata: a.project.metadata,
      projectFilePath: a.path,
      comparisonFilePath: '',
      hasUnsavedChanges: false,
    );
  }

  return state;
}
