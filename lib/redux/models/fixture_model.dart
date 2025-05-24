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

  FixtureModel({
    this.uid = '',
    this.fid = 0,
    this.sequence = 0,
    this.dmxAddress = const DMXAddressModel.unknown(),
    this.typeId = '',
    this.locationId = '',
    this.mode = '',
    this.powerPatch = '',
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
    String? powerPatch,
    String? mode,
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
