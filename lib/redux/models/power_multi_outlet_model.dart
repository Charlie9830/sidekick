import 'dart:convert';

import 'package:sidekick/redux/models/location_model.dart';

class PowerMultiOutletModel {
  final String uid;
  final String locationId;
  final String name;
  final int desiredSpareCircuits;

  PowerMultiOutletModel({
    required this.uid,
    required this.locationId,
    required this.name,
    required this.desiredSpareCircuits,
  });

  const PowerMultiOutletModel.none()
      : uid = "none",
        locationId = '',
        name = '',
        desiredSpareCircuits = 0;

  static String getName({
    required int multiNumber,
    required LocationModel location,
  }) {
    return location.getPrefixedPowerMulti(multiNumber);
  }

  LocationModel lookupLocation(Map<String, LocationModel> locations) {
    return locations[locationId] ?? const LocationModel.none();
  }

  PowerMultiOutletModel copyWith({
    String? uid,
    String? locationId,
    String? name,
    int? desiredSpareCircuits,
  }) {
    return PowerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      desiredSpareCircuits: desiredSpareCircuits ?? this.desiredSpareCircuits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'locationId': locationId,
      'name': name,
    };
  }

  factory PowerMultiOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerMultiOutletModel(
      uid: map['uid'] ?? '',
      locationId: map['locationId'] ?? '',
      name: map['name'] ?? '',
      desiredSpareCircuits: map['desiredSpareCircuits'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerMultiOutletModel.fromJson(String source) =>
      PowerMultiOutletModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'PowerMultiOutletModel(uid: $uid, locationId: $locationId, name: $name)';

  // Do not remove. You are actually using Object equality for this.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PowerMultiOutletModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
