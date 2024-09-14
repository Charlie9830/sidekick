import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/file_state.dart';

FileState fileStateReducer(FileState state, dynamic action) {
  return switch (action) {
    SetImportFilePath a => state.copyWith(fixtureImportPath: a.path),
    SetLastUsedProjectDirectory a => state.copyWith(projectFilePath: a.path),
    SetLastUsedProjectDirectory a =>
      state.copyWith(lastUsedProjectDirectory: a.path),
    SetProjectFileMetadata a => state.copyWith(projectMetadata: a.metadata),
    OpenProject a => state.copyWith(
        lastUsedProjectDirectory: a.parentDirectory,
        projectMetadata: a.project.metadata,
        projectFilePath: a.path,
      ),
    _ => state
  };
}
