import 'dart:convert';

const int kPersistentSettingsFileVersion = 1;

class PersistentSettingsModel {
  final int fileVersion;
  final String fixtureTypeDatabasePath;

  PersistentSettingsModel({
    this.fixtureTypeDatabasePath = '',
    required this.fileVersion,
  });

  const PersistentSettingsModel.initial()
      : fixtureTypeDatabasePath = '',
        fileVersion = kPersistentSettingsFileVersion;

  Map<String, dynamic> toMap() {
    return {
      'fileVersion': fileVersion,
      'fixtureTypeDatabasePath': fixtureTypeDatabasePath,
    };
  }

  factory PersistentSettingsModel.fromMap(Map<String, dynamic> map) {
    return PersistentSettingsModel(
      fileVersion: map['fileVersion']?.toInt() ?? 0,
      fixtureTypeDatabasePath: map['fixtureTypeDatabasePath'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PersistentSettingsModel.fromJson(String source) =>
      PersistentSettingsModel.fromMap(json.decode(source));

  PersistentSettingsModel copyWith({
    int? fileVersion,
    String? fixtureTypeDatabasePath,
  }) {
    return PersistentSettingsModel(
      fileVersion: fileVersion ?? this.fileVersion,
      fixtureTypeDatabasePath:
          fixtureTypeDatabasePath ?? this.fixtureTypeDatabasePath,
    );
  }
}
