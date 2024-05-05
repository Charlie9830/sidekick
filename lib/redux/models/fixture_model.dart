import 'dart:convert';

import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_mode_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

class FixtureModel {
  final String uid;
  final int fid;
  final int sequence;
  final DMXAddressModel dmxAddress;
  final FixtureTypeModel type;
  final FixtureModeModel mode;
  final String location;
  final String dataMulti;
  final String dataPatch;
  final String powerMulti;
  final int powerPatch;

  FixtureModel({
    this.uid = '',
    this.fid = 0,
    this.sequence = 0,
    this.dmxAddress = const DMXAddressModel.unknown(),
    this.type = const FixtureTypeModel.unknown(),
    this.mode = const FixtureModeModel.unknown(),
    this.location = '',
    this.dataMulti = '',
    this.dataPatch = '',
    this.powerMulti = '',
    this.powerPatch = 0,
  });

  FixtureModel copyWith({
    String? uid,
    int? fid,
    int? sequence,
    DMXAddressModel? dmxAddress,
    FixtureTypeModel? type,
    FixtureModeModel? mode,
    String? location,
    String? dataMulti,
    String? dataPatch,
    String? powerMulti,
    int? powerPatch,
  }) {
    return FixtureModel(
      uid: uid ?? this.uid,
      fid: fid ?? this.fid,
      sequence: sequence ?? this.sequence,
      dmxAddress: dmxAddress ?? this.dmxAddress,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      location: location ?? this.location,
      dataMulti: dataMulti ?? this.dataMulti,
      dataPatch: dataPatch ?? this.dataPatch,
      powerMulti: powerMulti ?? this.powerMulti,
      powerPatch: powerPatch ?? this.powerPatch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fid': fid,
      'sequence': sequence,
      'dmxAddress': dmxAddress.toMap(),
      'type': type.toMap(),
      'mode': mode.toMap(),
      'location': location,
      'dataMulti': dataMulti,
      'dataPatch': dataPatch,
      'powerMulti': powerMulti,
      'powerPatch': powerPatch,
    };
  }

  factory FixtureModel.fromMap(Map<String, dynamic> map) {
    return FixtureModel(
      uid: map['uid'] ?? '',
      fid: map['fid']?.toInt() ?? 0,
      sequence: map['sequence']?.toInt() ?? 0,
      dmxAddress: DMXAddressModel.fromMap(map['dmxAddress']),
      type: FixtureTypeModel.fromMap(map['type']),
      mode: FixtureModeModel.fromMap(map['mode']),
      location: map['location'] ?? '',
      dataMulti: map['dataMulti'] ?? '',
      dataPatch: map['dataPatch'] ?? '',
      powerMulti: map['powerMulti'] ?? '',
      powerPatch: map['powerPatch']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureModel.fromJson(String source) =>
      FixtureModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'FixtureModel(uid: $uid, fid: $fid, sequence: $sequence, dmxAddress: $dmxAddress, type: $type, mode: $mode, location: $location, dataMulti: $dataMulti, dataPatch: $dataPatch, powerMulti: $powerMulti, powerPatch: $powerPatch)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FixtureModel &&
        other.uid == uid &&
        other.fid == fid &&
        other.sequence == sequence &&
        other.dmxAddress == dmxAddress &&
        other.type == type &&
        other.mode == mode &&
        other.location == location &&
        other.dataMulti == dataMulti &&
        other.dataPatch == dataPatch &&
        other.powerMulti == powerMulti &&
        other.powerPatch == powerPatch;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        fid.hashCode ^
        sequence.hashCode ^
        dmxAddress.hashCode ^
        type.hashCode ^
        mode.hashCode ^
        location.hashCode ^
        dataMulti.hashCode ^
        dataPatch.hashCode ^
        powerMulti.hashCode ^
        powerPatch.hashCode;
  }
}
