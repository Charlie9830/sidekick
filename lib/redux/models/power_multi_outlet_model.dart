// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerMultiOutletModel extends Outlet
    implements Comparable<PowerMultiOutletModel> {
  final int desiredSpareCircuits;
  final List<PowerOutletModel> children;
  final PowerMultiRackAssignment parentRack;

  PowerMultiOutletModel({
    required String uid,
    required String locationId,
    required this.parentRack,
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
        parentRack = const PowerMultiRackAssignment.unassigned(),
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
    PowerMultiRackAssignment? parentRack,
    List<PowerOutletModel>? children,
  }) {
    return PowerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
      desiredSpareCircuits: desiredSpareCircuits ?? this.desiredSpareCircuits,
      name: name ?? this.name,
      parentRack: parentRack ?? this.parentRack,
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
      'parentRack': parentRack.toMap(),
    };
  }

  static int getHighestChannelNumber(List<PowerMultiOutletModel> multis) {
    int number = 1;

    for (final multi in multis) {
      number = multi.parentRack.channel >= number
          ? multi.parentRack.channel
          : number;
    }

    return number;
  }

  factory PowerMultiOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerMultiOutletModel(
      uid: map['uid'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
      desiredSpareCircuits: map['desiredSpareCircuits']?.toInt() ?? 0,
      name: map['name'] ?? '',
      parentRack: map['parentRack'] == null
          ? const PowerMultiRackAssignment.unassigned()
          : PowerMultiRackAssignment.fromMap(map['parentRack']),
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

class PowerMultiRackAssignment {
  final String rackId;
  final int channel;

  const PowerMultiRackAssignment({
    required this.rackId,
    required this.channel,
  });

  bool get isAssigned => channel != 0 && rackId.isNotEmpty;

  const PowerMultiRackAssignment.unassigned()
      : rackId = '',
        channel = 0;

  PowerMultiRackAssignment copyWith({
    String? rackId,
    int? channel,
  }) {
    return PowerMultiRackAssignment(
      rackId: rackId ?? this.rackId,
      channel: channel ?? this.channel,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rackId': rackId,
      'channel': channel,
    };
  }

  factory PowerMultiRackAssignment.fromMap(Map<String, dynamic> map) {
    return PowerMultiRackAssignment(
      rackId: map['rackId'] as String,
      channel: map['channel'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerMultiRackAssignment.fromJson(String source) =>
      PowerMultiRackAssignment.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
