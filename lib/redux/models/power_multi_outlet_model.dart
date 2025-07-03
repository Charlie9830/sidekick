import 'dart:convert';

import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerMultiOutletModel extends Outlet
    implements Comparable<PowerMultiOutletModel> {
  final int desiredSpareCircuits;
  final List<PowerOutletModel> children;

  PowerMultiOutletModel({
    required String uid,
    required String locationId,
    int number = 0,
    String name = '',
    required this.desiredSpareCircuits,
    required this.children,
  }) : super(
          uid: uid,
          locationId: locationId,
          number: number,
          name: name,
        );

  const PowerMultiOutletModel.none()
      : desiredSpareCircuits = 0,
        children = const [],
        super(locationId: '', uid: '', number: 0, name: '');

  LocationModel lookupLocation(Map<String, LocationModel> locations) {
    return locations[locationId] ?? const LocationModel.none();
  }

  @override
  PowerMultiOutletModel copyWith({
    String? uid,
    String? locationId,
    int? number,
    int? desiredSpareCircuits,
    String? name,
    List<PowerOutletModel>? children,
  }) {
    return PowerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
      desiredSpareCircuits: desiredSpareCircuits ?? this.desiredSpareCircuits,
      name: name ?? this.name,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'locationId': locationId,
      'number': number,
      'desiredSpareCircuits': desiredSpareCircuits,
      'name': name,
      'children': children.map((x) => x.toMap()).toList(),
    };
  }

  factory PowerMultiOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerMultiOutletModel(
      uid: map['uid'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
      desiredSpareCircuits: map['desiredSpareCircuits']?.toInt() ?? 0,
      name: map['name'] ?? '',
      children: List<PowerOutletModel>.from(
        ((map['children'] ?? []) as List<dynamic>).map<PowerOutletModel>(
          (x) => PowerOutletModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
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
