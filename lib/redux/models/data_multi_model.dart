import 'dart:convert';

class DataMultiModel {
  final String uid;
  final String name;
  final String locationId;
  DataMultiModel({
    this.uid = '',
    this.name = '',
    this.locationId = '',
  });

  DataMultiModel copyWith({
    String? uid,
    String? name,
    String? locationId,
  }) {
    return DataMultiModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'locationId': locationId,
    };
  }

  factory DataMultiModel.fromMap(Map<String, dynamic> map) {
    return DataMultiModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      locationId: map['locationId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DataMultiModel.fromJson(String source) =>
      DataMultiModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'DataMultiModel(uid: $uid, name: $name, locationId: $locationId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataMultiModel &&
        other.uid == uid &&
        other.name == name &&
        other.locationId == locationId;
  }

  @override
  int get hashCode => uid.hashCode ^ name.hashCode ^ locationId.hashCode;
}
