import 'dart:convert';

const kProjectFileVersion = 1;

class ProjectFileMetadataModel {
  final int fileVersion;
  final String created;
  final String modified;

  ProjectFileMetadataModel({
    required this.fileVersion,
    required this.created,
    required this.modified,
  });

  const ProjectFileMetadataModel.initial()
      : fileVersion = kProjectFileVersion,
        created = '',
        modified = '';

  Map<String, dynamic> toMap() {
    return {
      'fileVersion': fileVersion,
      'created': created,
      'modified': modified,
    };
  }

  factory ProjectFileMetadataModel.fromMap(Map<String, dynamic> map) {
    return ProjectFileMetadataModel(
      fileVersion: map['fileVersion']?.toInt() ?? 0,
      created: map['created'] ?? '',
      modified: map['modified'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectFileMetadataModel.fromJson(String source) =>
      ProjectFileMetadataModel.fromMap(json.decode(source));

  ProjectFileMetadataModel copyWith({
    int? fileVersion,
    String? created,
    String? modified,
  }) {
    return ProjectFileMetadataModel(
      fileVersion: fileVersion ?? this.fileVersion,
      created: created ?? this.created,
      modified: modified ?? this.modified,
    );
  }
}
