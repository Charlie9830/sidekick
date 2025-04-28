import 'dart:convert';

const int kPersistentSettingsFileVersion = 1;

class PersistentSettingsModel {
  final int fileVersion;
  final String fixtureTypeDatabasePath;
  final String fixtureMappingFilePath;

  PersistentSettingsModel({
    this.fixtureTypeDatabasePath = '',
    required this.fileVersion,
    this.fixtureMappingFilePath = '',
  });

  const PersistentSettingsModel.initial()
      : fixtureTypeDatabasePath = '',
        fixtureMappingFilePath = '',
        fileVersion = kPersistentSettingsFileVersion;

  Map<String, dynamic> toMap() {
    return {
      'fileVersion': fileVersion,
      'fixtureTypeDatabasePath': fixtureTypeDatabasePath,
      'fixtureMappingFilePath': fixtureMappingFilePath,
    };
  }

  factory PersistentSettingsModel.fromMap(Map<String, dynamic> map) {
    return PersistentSettingsModel(
      fileVersion: map['fileVersion']?.toInt() ?? 0,
      fixtureTypeDatabasePath: map['fixtureTypeDatabasePath'] ?? '',
      fixtureMappingFilePath: map['fixtureMappingFilePath'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PersistentSettingsModel.fromJson(String source) =>
      PersistentSettingsModel.fromMap(json.decode(source));

  PersistentSettingsModel copyWith({
    int? fileVersion,
    String? fixtureTypeDatabasePath,
    String? fixtureMappingFilePath,
  }) {
    return PersistentSettingsModel(
      fileVersion: fileVersion ?? this.fileVersion,
      fixtureTypeDatabasePath:
          fixtureTypeDatabasePath ?? this.fixtureTypeDatabasePath,
      fixtureMappingFilePath:
          fixtureMappingFilePath ?? this.fixtureMappingFilePath,
    );
  }
}
