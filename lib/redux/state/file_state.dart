import 'package:sidekick/serialization/project_file_metadata_model.dart';

class FileState {
  final String fixtureImportPath;
  final String projectFilePath;
  final String lastUsedProjectDirectory;
  final ProjectFileMetadataModel projectMetadata;

  FileState({
    this.fixtureImportPath = "",
    this.projectFilePath = "",
    this.lastUsedProjectDirectory = "",
    this.projectMetadata = const ProjectFileMetadataModel.initial(),
  });

  FileState.initial()
      : fixtureImportPath = "",
        projectFilePath = "",
        lastUsedProjectDirectory = "",
        projectMetadata = const ProjectFileMetadataModel.initial();

  FileState copyWith({
    String? fixtureImportPath,
    String? projectFilePath,
    String? lastUsedProjectDirectory,
    ProjectFileMetadataModel? projectMetadata,
  }) {
    return FileState(
      fixtureImportPath: fixtureImportPath ?? this.fixtureImportPath,
      projectFilePath: projectFilePath ?? this.projectFilePath,
      lastUsedProjectDirectory:
          lastUsedProjectDirectory ?? this.lastUsedProjectDirectory,
      projectMetadata: projectMetadata ?? this.projectMetadata,
    );
  }
}
