// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class FileState {
  final String fixturePatchImportPath;
  final String projectFilePath;
  final String lastUsedProjectDirectory;
  final ProjectFileMetadataModel projectMetadata;
  final String fixtureTypeDatabasePath;
  final bool isFixtureTypeDatabasePathValid;
  final String fixtureMappingFilePath;

  FileState({
    this.fixturePatchImportPath = "",
    this.projectFilePath = "",
    this.lastUsedProjectDirectory = "",
    this.fixtureTypeDatabasePath = "",
    this.projectMetadata = const ProjectFileMetadataModel.initial(),
    this.isFixtureTypeDatabasePathValid = false,
    this.fixtureMappingFilePath = '',
  });

  FileState.initial()
      : fixturePatchImportPath = "",
        projectFilePath = "",
        lastUsedProjectDirectory = "",
        fixtureTypeDatabasePath = "",
        projectMetadata = const ProjectFileMetadataModel.initial(),
        isFixtureTypeDatabasePathValid = false,
        fixtureMappingFilePath = '';

  FileState copyWith({
    String? fixturePatchImportPath,
    String? projectFilePath,
    String? lastUsedProjectDirectory,
    ProjectFileMetadataModel? projectMetadata,
    String? fixtureTypeDatabasePath,
    bool? isFixtureTypeDatabasePathValid,
    String? fixtureMappingFilePath,
  }) {
    return FileState(
      fixturePatchImportPath:
          fixturePatchImportPath ?? this.fixturePatchImportPath,
      projectFilePath: projectFilePath ?? this.projectFilePath,
      lastUsedProjectDirectory:
          lastUsedProjectDirectory ?? this.lastUsedProjectDirectory,
      projectMetadata: projectMetadata ?? this.projectMetadata,
      fixtureTypeDatabasePath:
          fixtureTypeDatabasePath ?? this.fixtureTypeDatabasePath,
      isFixtureTypeDatabasePathValid:
          isFixtureTypeDatabasePathValid ?? this.isFixtureTypeDatabasePathValid,
      fixtureMappingFilePath:
          fixtureMappingFilePath ?? this.fixtureMappingFilePath,
    );
  }
}
