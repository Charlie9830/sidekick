import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

class FixtureModel implements ModelCollectionMember {
  @override
  final String uid;
  final int fid;
  final int sequence;
  final DMXAddressModel dmxAddress;
  final String typeId;
  final String locationId;
  final String dataMulti;
  final String dataPatch;
  final String powerMultiId;
  final int powerPatch;

  FixtureModel({
    this.uid = '',
    this.fid = 0,
    this.sequence = 0,
    this.dmxAddress = const DMXAddressModel.unknown(),
    this.typeId = '',
    this.locationId = '',
    this.dataMulti = '',
    this.dataPatch = '',
    this.powerMultiId = '',
    this.powerPatch = 0,
  });

  LocationModel lookupLocation(Map<String, LocationModel> locations) {
    return locations[locationId] ?? const LocationModel.none();
  }

  String lookupPowerMultiName(Map<String, PowerMultiOutletModel> powerMultis) {
    return powerMultis[powerMultiId]?.name ?? "## BAD LOOKUP ##";
  }

  FixtureModel copyWith({
    String? uid,
    int? fid,
    int? sequence,
    DMXAddressModel? dmxAddress,
    String? typeId,
    String? locationId,
    String? dataMulti,
    String? dataPatch,
    String? powerMultiId,
    int? powerPatch,
  }) {
    return FixtureModel(
      uid: uid ?? this.uid,
      fid: fid ?? this.fid,
      sequence: sequence ?? this.sequence,
      dmxAddress: dmxAddress ?? this.dmxAddress,
      typeId: typeId ?? this.typeId,
      locationId: locationId ?? this.locationId,
      dataMulti: dataMulti ?? this.dataMulti,
      dataPatch: dataPatch ?? this.dataPatch,
      powerMultiId: powerMultiId ?? this.powerMultiId,
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
      'dataMulti': dataMulti,
      'dataPatch': dataPatch,
      'powerMulti': powerMultiId,
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
      dataMulti: map['dataMulti'] ?? '',
      dataPatch: map['dataPatch'] ?? '',
      powerMultiId: map['powerMulti'] ?? '',
      powerPatch: map['powerPatch']?.toInt() ?? 0,
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
        other.locationId == locationId &&
        other.dataMulti == dataMulti &&
        other.dataPatch == dataPatch &&
        other.powerMultiId == powerMultiId &&
        other.powerPatch == powerPatch;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        fid.hashCode ^
        sequence.hashCode ^
        dmxAddress.hashCode ^
        typeId.hashCode ^
        locationId.hashCode ^
        dataMulti.hashCode ^
        dataPatch.hashCode ^
        powerMultiId.hashCode ^
        powerPatch.hashCode;
  }

  static Map<String, FixtureModel> sort(Map<String, FixtureModel> fixtures,
      Map<String, LocationModel> locations) {
    final fixturesByLocation =
        fixtures.values.groupListsBy((fixture) => fixture.locationId);

    final sortedFixturesByLocation = fixturesByLocation.map(
        (locationId, fixtures) => MapEntry(
            locationId, fixtures.sorted((a, b) => a.sequence - b.sequence)));

    return Map<String, FixtureModel>.fromEntries(sortedFixturesByLocation
        .values.flattened
        .map((fixture) => MapEntry(fixture.uid, fixture)));
  }
}
