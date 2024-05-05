import 'dart:convert';

import 'package:sidekick/redux/models/location_model.dart';

class PowerMultiOutletModel {
  final String uid;
  final String locationId;
  final String name;

  PowerMultiOutletModel({
    required this.uid,
    required this.locationId,
    required this.name,
  });

  const PowerMultiOutletModel.none()
      : uid = "none",
        locationId = '',
        name = '';

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
  }) {
    return PowerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerMultiOutletModel.fromJson(String source) =>
      PowerMultiOutletModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'PowerMultiOutletModel(uid: $uid, locationId: $locationId, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PowerMultiOutletModel &&
        other.uid == uid &&
        other.locationId == locationId &&
        other.name == name;
  }

  @override
  int get hashCode => uid.hashCode ^ locationId.hashCode ^ name.hashCode;
}
