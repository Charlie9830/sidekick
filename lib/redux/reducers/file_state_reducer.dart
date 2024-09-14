import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/file_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

FileState fileStateReducer(FileState state, dynamic a) {
  if (a is NewProject) {
    return state.copyWith(
      fixtureImportPath: '',
      projectFilePath: '',
      projectMetadata: const ProjectFileMetadataModel.initial(),
    );
  }

  if (a is SetImportFilePath) {
    return state.copyWith(fixtureImportPath: a.path);
  }

  if (a is SetLastUsedProjectDirectory) {
    return state.copyWith(projectFilePath: a.path);
  }

  if (a is SetLastUsedProjectDirectory) {
    return state.copyWith(lastUsedProjectDirectory: a.path);
  }

  if (a is SetProjectFileMetadata) {
    return state.copyWith(projectMetadata: a.metadata);
  }

  if (a is OpenProject) {
    return state.copyWith(
      lastUsedProjectDirectory: a.parentDirectory,
      projectMetadata: a.project.metadata,
      projectFilePath: a.path,
    );
  }

  return state;
}
