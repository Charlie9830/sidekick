import 'package:sidekick/persistent_settings/persistent_settings_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class FileState {
  final String fixturePatchImportPath;
  final String projectFilePath;
  final String lastUsedProjectDirectory;
  final ProjectFileMetadataModel projectMetadata;
  final ImportSettingsModel importSettings;
  final String fixtureTypeDatabasePath;
  final bool isFixtureTypeDatabasePathValid;

  FileState({
    this.fixturePatchImportPath = "",
    this.projectFilePath = "",
    this.lastUsedProjectDirectory = "",
    this.fixtureTypeDatabasePath = "",
    this.importSettings = const ImportSettingsModel(),
    this.projectMetadata = const ProjectFileMetadataModel.initial(),
    this.isFixtureTypeDatabasePathValid = false,
  });

  FileState.initial()
      : fixturePatchImportPath = "",
        projectFilePath = "",
        lastUsedProjectDirectory = "",
        fixtureTypeDatabasePath = "",
        projectMetadata = const ProjectFileMetadataModel.initial(),
        importSettings = const ImportSettingsModel(),
        isFixtureTypeDatabasePathValid = false;

  FileState copyWith({
    String? fixturePatchImportPath,
    String? projectFilePath,
    String? lastUsedProjectDirectory,
    ProjectFileMetadataModel? projectMetadata,
    ImportSettingsModel? importSettings,
    String? fixtureTypeDatabasePath,
    bool? isFixtureTypeDatabasePathValid,
  }) {
    return FileState(
      fixturePatchImportPath:
          fixturePatchImportPath ?? this.fixturePatchImportPath,
      projectFilePath: projectFilePath ?? this.projectFilePath,
      lastUsedProjectDirectory:
          lastUsedProjectDirectory ?? this.lastUsedProjectDirectory,
      projectMetadata: projectMetadata ?? this.projectMetadata,
      importSettings: importSettings ?? this.importSettings,
      fixtureTypeDatabasePath:
          fixtureTypeDatabasePath ?? this.fixtureTypeDatabasePath,
      isFixtureTypeDatabasePathValid:
          isFixtureTypeDatabasePathValid ?? this.isFixtureTypeDatabasePathValid,
    );
  }
}
