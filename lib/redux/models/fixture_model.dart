// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/extension_methods/mvr_matrix_extensions.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';

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
  final String powerMultiOutletId;
  final bool hasMatrixData;
  final double x;
  final double y;
  final double z;

  /// The fixture's orientation in world space, with no translation.
  ///
  /// Combine with [x], [y] and [z] via [transform] to map fixture-local points
  /// (such as wiring object positions) into the world.
  final MVRMatrix rotation;

  FixtureModel({
    this.uid = '',
    this.fid = 0,
    this.sequence = 0,
    this.dmxAddress = const DMXAddressModel.unknown(),
    this.typeId = '',
    this.locationId = '',
    this.mode = '',
    this.powerPatch = '',
    this.powerMultiOutletId = '',
    this.hasMatrixData = false,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.rotation = const MVRMatrix.identity(),
  });

  /// The fixture's world transform: [rotation] placed at ([x], [y], [z]).
  MVRMatrix get transform => rotation.withTranslation(x, y, z);

  /// Rotation about the X axis in degrees.
  double get rotationX => rotation.rotationX;

  /// Rotation about the Y axis in degrees.
  double get rotationY => rotation.rotationY;

  /// Rotation about the Z axis in degrees.
  double get rotationZ => rotation.rotationZ;

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
    String? powerMultiOutletId,
    bool? hasMatrixData,
    double? x,
    double? y,
    double? z,
    MVRMatrix? rotation,
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
      powerMultiOutletId: powerMultiOutletId ?? this.powerMultiOutletId,
      hasMatrixData: hasMatrixData ?? this.hasMatrixData,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      rotation: rotation ?? this.rotation,
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
      'rotation': rotation.toJson(),
      'hasMatrixData': hasMatrixData,
      'powerMultiOutletId': powerMultiOutletId,
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
      rotation: MVRMatrixExtensions.fromJson(map['rotation']),
      hasMatrixData: map['hasMatrixData'] ?? false,
      powerMultiOutletId: map['powerMultiOutletId'] ?? '',
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

  static Map<String, FixtureModel> sort(
    Map<String, FixtureModel> fixtures,
    Map<String, LocationModel> locations,
  ) {
    final fixturesByLocation = fixtures.values.groupListsBy(
      (fixture) => fixture.locationId,
    );

    final sortedFixturesByLocation = locations.values.map(
      (location) => MapEntry(
        location.uid,
        fixturesByLocation[location.uid]?.sorted() ?? [],
      ),
    );

    return sortedFixturesByLocation
        .map((entry) => entry.value)
        .flattened
        .toModelMap();
  }

  @override
  int compareTo(other) {
    return sequence - other.sequence;
  }

  double distanceTo(FixtureModel other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  double distanceToCoord(double otherX, double otherY, double otherZ) {
    final dx = x - otherX;
    final dy = y - otherY;
    final dz = z - otherZ;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}
