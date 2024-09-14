import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class DataMultiModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final String locationId;
  final int number;

  DataMultiModel({
    this.uid = '',
    this.name = '',
    this.locationId = '',
    this.number = 0,
  });

  DataMultiModel copyWith({
    String? uid,
    String? name,
    String? locationId,
    int? number,
  }) {
    return DataMultiModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'number': number,
    };
  }

  factory DataMultiModel.fromMap(Map<String, dynamic> map) {
    return DataMultiModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataMultiModel.fromJson(String source) =>
      DataMultiModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataMultiModel(uid: $uid, name: $name, locationId: $locationId, number: $number)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataMultiModel &&
        other.uid == uid &&
        other.name == name &&
        other.locationId == locationId &&
        other.number == number;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ name.hashCode ^ locationId.hashCode ^ number.hashCode;
  }
}
