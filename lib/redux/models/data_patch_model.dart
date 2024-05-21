import 'dart:convert';

class DataPatchModel {
  final String uid;
  final String name;
  final int universe;
  final String multiId;
  final String locationId;

  DataPatchModel({
    required this.uid,
    required this.name,
    required this.universe,
    required this.multiId,
    required this.locationId,
  });

  DataPatchModel copyWith({
    String? uid,
    String? name,
    int? universe,
    String? multiId,
    String? locationId,
  }) {
    return DataPatchModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      universe: universe ?? this.universe,
      multiId: multiId ?? this.multiId,
      locationId: locationId ?? this.locationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'universe': universe,
      'multiId': multiId,
      'locationId': locationId,
    };
  }

  factory DataPatchModel.fromMap(Map<String, dynamic> map) {
    return DataPatchModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      universe: map['universe']?.toInt() ?? 0,
      multiId: map['multiId'] ?? '',
      locationId: map['locationId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DataPatchModel.fromJson(String source) =>
      DataPatchModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataPatchModel(uid: $uid, name: $name, universe: $universe, multiId: $multiId, locationId: $locationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DataPatchModel &&
      other.uid == uid &&
      other.name == name &&
      other.universe == universe &&
      other.multiId == multiId &&
      other.locationId == locationId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      name.hashCode ^
      universe.hashCode ^
      multiId.hashCode ^
      locationId.hashCode;
  }
}
