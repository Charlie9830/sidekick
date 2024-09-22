import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class FileState {
  final String fixturePatchImportPath;
  final String projectFilePath;
  final String lastUsedProjectDirectory;
  final ProjectFileMetadataModel projectMetadata;
  final ImportSettingsModel importSettings;

  FileState({
    this.fixturePatchImportPath = "",
    this.projectFilePath = "",
    this.lastUsedProjectDirectory = "",
    this.importSettings = const ImportSettingsModel(),
    this.projectMetadata = const ProjectFileMetadataModel.initial(),
  });

  FileState.initial()
      : fixturePatchImportPath = "",
        projectFilePath = "",
        lastUsedProjectDirectory = "",
        projectMetadata = const ProjectFileMetadataModel.initial(),
        importSettings = const ImportSettingsModel();

  FileState copyWith({
    String? fixturePatchImportPath,
    String? projectFilePath,
    String? lastUsedProjectDirectory,
    ProjectFileMetadataModel? projectMetadata,
    ImportSettingsModel? importSettings,
  }) {
    return FileState(
      fixturePatchImportPath: fixturePatchImportPath ?? this.fixturePatchImportPath,
      projectFilePath: projectFilePath ?? this.projectFilePath,
      lastUsedProjectDirectory:
          lastUsedProjectDirectory ?? this.lastUsedProjectDirectory,
      projectMetadata: projectMetadata ?? this.projectMetadata,
      importSettings: importSettings ?? this.importSettings,
    );
  }
}
