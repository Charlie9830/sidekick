// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';

class HoistModel implements ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final String locationId;
  final int locationIndex;
  final HoistControllerChannelAssignment parentController;

  HoistModel({
    required this.uid,
    required this.name,
    required this.locationId,
    required this.locationIndex,
    required this.parentController,
  });

  HoistModel copyWith({
    String? uid,
    String? name,
    String? locationId,
    int? locationIndex,
    HoistControllerChannelAssignment? parentController,
  }) {
    return HoistModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
      locationIndex: locationIndex ?? this.locationIndex,
      parentController: parentController ?? this.parentController,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'locationIndex': locationIndex,
      'parentController': parentController.toMap(),
    };
  }

  factory HoistModel.fromMap(Map<String, dynamic> map) {
    return HoistModel(
      uid: (map['uid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      locationId: (map['locationId'] ?? '') as String,
      locationIndex: (map['locationIndex'] ?? 0) as int,
      parentController: HoistControllerChannelAssignment.fromMap(
          map['parentController'] as Map<String, dynamic>),
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
}

class HoistControllerChannelAssignment {
  final String controllerId;
  final int channel;

  bool get isAssigned =>
      this != const HoistControllerChannelAssignment.unassigned();

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
