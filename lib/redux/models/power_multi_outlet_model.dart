import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';

class PowerMultiOutletModel extends ModelCollectionMember
    implements Comparable<PowerMultiOutletModel> {
  @override
  final String uid;
  final String locationId;
  final int number;
  final int desiredSpareCircuits;
  final String name;

  PowerMultiOutletModel({
    required this.uid,
    required this.locationId,
    required this.number,
    required this.desiredSpareCircuits,
    required this.name,
  });

  const PowerMultiOutletModel.none()
      : uid = "none",
        locationId = '',
        number = 1,
        desiredSpareCircuits = 0,
        name = '';

  LocationModel lookupLocation(Map<String, LocationModel> locations) {
    return locations[locationId] ?? const LocationModel.none();
  }

  PowerMultiOutletModel copyWith({
    String? uid,
    String? locationId,
    int? number,
    int? desiredSpareCircuits,
    String? name,
  }) {
    return PowerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
      desiredSpareCircuits: desiredSpareCircuits ?? this.desiredSpareCircuits,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'locationId': locationId,
      'number': number,
      'desiredSpareCircuits': desiredSpareCircuits,
      'name': name,
    };
  }

  factory PowerMultiOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerMultiOutletModel(
      uid: map['uid'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
      desiredSpareCircuits: map['desiredSpareCircuits']?.toInt() ?? 0,
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerMultiOutletModel.fromJson(String source) =>
      PowerMultiOutletModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'PowerMultiOutletModel(uid: $uid, locationId: $locationId, number: $number, desiredSpareCircuits: $desiredSpareCircuits, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PowerMultiOutletModel &&
        other.uid == uid &&
        other.locationId == locationId &&
        other.number == number &&
        other.desiredSpareCircuits == desiredSpareCircuits &&
        other.name == name;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        locationId.hashCode ^
        number.hashCode ^
        desiredSpareCircuits.hashCode ^
        name.hashCode;
  }

  @override
  int compareTo(PowerMultiOutletModel other) {
    return number - other.number;
  }
}
