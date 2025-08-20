// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

class HoistModel extends Outlet implements Comparable<HoistModel> {
  final HoistControllerChannelAssignment parentController;
  final String controllerNote;

  HoistModel({
    required super.uid,
    required super.name,
    required super.locationId,
    required this.parentController,
    required super.number,
    required this.controllerNote,
  });

  @override
  HoistModel copyWith({
    String? uid,
    String? name,
    String? locationId,
    HoistControllerChannelAssignment? parentController,
    int? number,
    String? controllerNote,
  }) {
    return HoistModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
      parentController: parentController ?? this.parentController,
      number: number ?? this.number,
      controllerNote: controllerNote ?? this.controllerNote,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'parentController': parentController.toMap(),
      'number': number,
      'controllerNote': controllerNote,
    };
  }

  factory HoistModel.fromMap(Map<String, dynamic> map) {
    return HoistModel(
      uid: (map['uid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      locationId: (map['locationId'] ?? '') as String,
      parentController: HoistControllerChannelAssignment.fromMap(
          map['parentController'] as Map<String, dynamic>),
      number: map['number'] ?? 0,
      controllerNote: map['controllerNote'] ?? '',
    );
  }

  @override
  String toString() {
    return '$name Chn: ${parentController.channel}';
  }

  String toJson() => json.encode(toMap());

  factory HoistModel.fromJson(String source) =>
      HoistModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static int getHighestChannelNumber(List<HoistModel> hoists) {
    int number = 1;

    for (final hoist in hoists) {
      number = hoist.parentController.channel >= number
          ? hoist.parentController.channel
          : number;
    }

    return number;
  }

  static String getDefaultName({
    required List<HoistModel> otherHoistsInLocation,
    required LocationModel location,
  }) {
    final withoutCablePicks = otherHoistsInLocation
        .where((hoist) => hoist.name.toLowerCase().contains('cp') == false)
        .where((hoist) => hoist.name.toLowerCase().contains('pick') == false);

    final countWithoutPicks = withoutCablePicks.length;

    final multiPrefix =
        location.multiPrefix.isEmpty ? location.name : location.multiPrefix;

    final lastMultiPrefixCharacter = multiPrefix.isNotEmpty
        ? multiPrefix.substring(multiPrefix.length - 1)
        : '';

    if (lastMultiPrefixCharacter.contains(RegExp(r'[0-9]'))) {
      return '$multiPrefix.${countWithoutPicks + 1}';
    } else {
      return '$multiPrefix ${countWithoutPicks + 1}';
    }
  }

  @override
  int compareTo(HoistModel other) {
    return number - other.number;
  }
}

class HoistControllerChannelAssignment {
  final String controllerId;
  final int channel;

  bool get isAssigned => channel != 0 && controllerId.isNotEmpty;

  HoistControllerChannelAssignment({
    required this.controllerId,
    required this.channel,
  });

  const HoistControllerChannelAssignment.unassigned()
      : controllerId = '',
        channel = 0;

  HoistControllerChannelAssignment copyWith({
    String? controllerId,
    int? channel,
  }) {
    return HoistControllerChannelAssignment(
      controllerId: controllerId ?? this.controllerId,
      channel: channel ?? this.channel,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'controllerId': controllerId,
      'channel': channel,
    };
  }

  factory HoistControllerChannelAssignment.fromMap(Map<String, dynamic> map) {
    return HoistControllerChannelAssignment(
      controllerId: (map['controllerId'] ?? '') as String,
      channel: (map['channel'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory HoistControllerChannelAssignment.fromJson(String source) =>
      HoistControllerChannelAssignment.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
