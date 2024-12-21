import 'dart:convert';

const kProjectFileVersion = 1;

class ProjectFileMetadataModel {
  final int fileVersion;
  final String created;
  final String modified;
  final String lastUsedExportDirectory;
  final String projectName;

  ProjectFileMetadataModel({
    required this.fileVersion,
    required this.created,
    required this.modified,
    required this.lastUsedExportDirectory,
    required this.projectName,
  });

  const ProjectFileMetadataModel.initial()
      : fileVersion = kProjectFileVersion,
        created = '',
        modified = '',
        lastUsedExportDirectory = '',
        projectName = '';

  Map<String, dynamic> toMap() {
    return {
      'fileVersion': fileVersion,
      'created': created,
      'modified': modified,
      'lastUsedExportDirectory': lastUsedExportDirectory,
      'projectName': projectName,
    };
  }

  factory ProjectFileMetadataModel.fromMap(Map<String, dynamic> map) {
    return ProjectFileMetadataModel(
      fileVersion: map['fileVersion']?.toInt() ?? 0,
      created: map['created'] ?? '',
      modified: map['modified'] ?? '',
      lastUsedExportDirectory: map['lastUsedExportDirectory'] ?? '',
      projectName: map['projectName'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectFileMetadataModel.fromJson(String source) =>
      ProjectFileMetadataModel.fromMap(json.decode(source));

  ProjectFileMetadataModel copyWith({
    int? fileVersion,
    String? created,
    String? modified,
    String? lastUsedExportDirectory,
    String? projectName,
  }) {
    return ProjectFileMetadataModel(
      fileVersion: fileVersion ?? this.fileVersion,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      lastUsedExportDirectory:
          lastUsedExportDirectory ?? this.lastUsedExportDirectory,
      projectName: projectName ?? this.projectName,
    );
  }
}
