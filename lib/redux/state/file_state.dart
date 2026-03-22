// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/export_error_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class FileState {
  final String fixturePatchImportPath;
  final String projectFilePath;
  final String lastUsedProjectDirectory;
  final ProjectFileMetadataModel projectMetadata;
  final String fixtureTypeDatabasePath;
  final bool isFixtureTypeDatabasePathValid;
  final String fixtureMappingFilePath;
  final String comparisonFilePath;
  final List<ExportErrorModel> exportErrors;
  final bool isValidatingExportData;

  FileState({
    this.fixturePatchImportPath = "",
    this.projectFilePath = "",
    this.lastUsedProjectDirectory = "",
    this.fixtureTypeDatabasePath = "",
    this.projectMetadata = const ProjectFileMetadataModel.initial(),
    this.isFixtureTypeDatabasePathValid = false,
    this.fixtureMappingFilePath = '',
    this.comparisonFilePath = '',
    this.exportErrors = const [],
    this.isValidatingExportData = false,
  });

  const FileState.initial()
      : fixturePatchImportPath = "",
        projectFilePath = "",
        lastUsedProjectDirectory = "",
        fixtureTypeDatabasePath = "",
        projectMetadata = const ProjectFileMetadataModel.initial(),
        isFixtureTypeDatabasePathValid = false,
        fixtureMappingFilePath = '',
        comparisonFilePath = '',
        exportErrors = const [],
        isValidatingExportData = false;

  FileState copyWith({
    String? fixturePatchImportPath,
    String? projectFilePath,
    String? lastUsedProjectDirectory,
    ProjectFileMetadataModel? projectMetadata,
    String? fixtureTypeDatabasePath,
    bool? isFixtureTypeDatabasePathValid,
    String? fixtureMappingFilePath,
    String? comparisonFilePath,
    List<ExportErrorModel>? exportErrors,
    bool? isValidatingExportData,
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
      comparisonFilePath: comparisonFilePath ?? this.comparisonFilePath,
      exportErrors: exportErrors ?? this.exportErrors,
      isValidatingExportData:
          isValidatingExportData ?? this.isValidatingExportData,
    );
  }
}
