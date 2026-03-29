// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class FixtureModel implements ModelCollectionMember, Comparable<FixtureModel> {
  @override
  final String uid;
  final int fid;
  final int sequence;
  final DMXAddressModel dmxAddress;
  final String typeId;
  final String locationId;
  final String mode;
  final String powerPatch;
  final bool hasMatrixData;
  final double x;
  final double y;
  final double z;
  final double rotationX;
  final double rotationY;
  final double rotationZ;

  FixtureModel({
    this.uid = '',
    this.fid = 0,
    this.sequence = 0,
    this.dmxAddress = const DMXAddressModel.unknown(),
    this.typeId = '',
    this.locationId = '',
    this.mode = '',
    this.powerPatch = '',
    this.hasMatrixData = false,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
  });

  LocationModel lookupLocation(Map<String, LocationModel> locations) {
    return locations[locationId] ?? const LocationModel.none();
  }

  FixtureModel copyWith({
    String? uid,
    int? fid,
    int? sequence,
    DMXAddressModel? dmxAddress,
    String? typeId,
    String? locationId,
    String? mode,
    String? powerPatch,
    bool? hasMatrixData,
    double? x,
    double? y,
    double? z,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
  }) {
    return FixtureModel(
      uid: uid ?? this.uid,
      fid: fid ?? this.fid,
      sequence: sequence ?? this.sequence,
      dmxAddress: dmxAddress ?? this.dmxAddress,
      typeId: typeId ?? this.typeId,
      locationId: locationId ?? this.locationId,
      mode: mode ?? this.mode,
      powerPatch: powerPatch ?? this.powerPatch,
      hasMatrixData: hasMatrixData ?? this.hasMatrixData,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fid': fid,
      'sequence': sequence,
      'dmxAddress': dmxAddress.toMap(),
      'typeId': typeId,
      'locationId': locationId,
      'mode': mode,
      'powerPatch': powerPatch,
      'x': x,
      'y': y,
      'z': z,
      'rotationX': rotationX,
      'rotationY': rotationY,
      'rotationZ': rotationZ,
      'hasMatrixData': hasMatrixData,
    };
  }

  factory FixtureModel.fromMap(Map<String, dynamic> map) {
    return FixtureModel(
      uid: map['uid'] ?? '',
      fid: map['fid']?.toInt() ?? 0,
      sequence: map['sequence']?.toInt() ?? 0,
      dmxAddress: DMXAddressModel.fromMap(map['dmxAddress']),
      typeId: map['typeId'],
      locationId: map['locationId'] ?? '',
      powerPatch: map['powerPatch'] is String ? map['powerPatch'] : '',
      mode: map['mode'] ?? '',
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
      z: map['z'] ?? 0,
      rotationX: map['rotationX'] ?? 0,
      rotationY: map['rotationY'] ?? 0,
      rotationZ: map['rotationZ'] ?? 0,
      hasMatrixData: map['hasMatrixData'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureModel.fromJson(String source) =>
      FixtureModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'FixtureModel(#$fid )';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FixtureModel &&
        other.uid == uid &&
        other.fid == fid &&
        other.sequence == sequence &&
        other.dmxAddress == dmxAddress &&
        other.typeId == typeId &&
        other.locationId == locationId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        fid.hashCode ^
        sequence.hashCode ^
        dmxAddress.hashCode ^
        typeId.hashCode ^
        locationId.hashCode;
  }

  static Map<String, FixtureModel> sort(Map<String, FixtureModel> fixtures,
      Map<String, LocationModel> locations) {
    final fixturesByLocation =
        fixtures.values.groupListsBy((fixture) => fixture.locationId);

    final sortedFixturesByLocation = fixturesByLocation
        .map((locationId, fixtures) => MapEntry(locationId, fixtures.sorted()));

    return Map<String, FixtureModel>.fromEntries(sortedFixturesByLocation
        .values.flattened
        .map((fixture) => MapEntry(fixture.uid, fixture)));
  }

  @override
  int compareTo(other) {
    return sequence - other.sequence;
  }
}
