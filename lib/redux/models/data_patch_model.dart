// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/redux/models/outlet.dart';

class DataPatchModel extends Outlet implements Comparable<DataPatchModel> {
  final int universe;
  final List<String> fixtureIds;
  final int startsAtFixtureId;
  final int endsAtFixtureId;
  final DataPatchRackAssignment parentRack;

  DataPatchModel({
    required String uid,
    required String locationId,
    int number = 0,
    String name = '',
    this.universe = 0,
    this.fixtureIds = const [],
    this.startsAtFixtureId = 0,
    this.endsAtFixtureId = 0,
    this.parentRack = const DataPatchRackAssignment.unassigned(),
  }) : super(
          uid: uid,
          locationId: locationId,
          number: number,
          name: name,
        );

  String get nameWithUniverse => '$name $universeLabel';

  String get universeWithName => '$universeLabel  ($name)';

  String get universeLabel => 'U$universe';

  @override
  DataPatchModel copyWith({
    int? universe,
    String? uid,
    String? locationId,
    String? name,
    int? number,
    List<String>? fixtureIds,
    int? startsAtFixtureId,
    int? endsAtFixtureId,
    DataPatchRackAssignment? parentRack,
  }) {
    return DataPatchModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      number: number ?? this.number,
      locationId: locationId ?? this.locationId,
      universe: universe ?? this.universe,
      fixtureIds: fixtureIds ?? this.fixtureIds,
      startsAtFixtureId: startsAtFixtureId ?? this.startsAtFixtureId,
      endsAtFixtureId: endsAtFixtureId ?? this.endsAtFixtureId,
      parentRack: parentRack ?? this.parentRack,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'number': number,
      'universe': universe,
      'fixtureIds': fixtureIds,
      'locationId': locationId,
      'startsAtFixtureId': startsAtFixtureId,
      'endsAtFixtureId': endsAtFixtureId,
      'parentRack': parentRack.toMap(),
    };
  }

  factory DataPatchModel.fromMap(Map<String, dynamic> map) {
    return DataPatchModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      number: map['number']?.toInt() ?? 0,
      universe: map['universe']?.toInt() ?? 0,
      fixtureIds: List<String>.from(map['fixtureIds']),
      locationId: map['locationId'] ?? '',
      startsAtFixtureId: map['startsAtFixtureId']?.toInt() ?? 0,
      endsAtFixtureId: map['endsAtFixtureId']?.toInt() ?? 0,
      parentRack: map['parentRack'] == null
          ? const DataPatchRackAssignment.unassigned()
          : DataPatchRackAssignment.fromMap(map['parentRack']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DataPatchModel.fromJson(String source) =>
      DataPatchModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataPatchModel(uid: $uid, name: $name, number: $number, universe: $universe, fixtureIds: $fixtureIds, locationId: $locationId, startsAtFixtureId: $startsAtFixtureId, endsAtFixtureId: $endsAtFixtureId)';
  }

  static int getHighestChannelNumber(List<DataPatchModel> patches) {
    int number = 1;

    for (final patch in patches) {
      number = patch.parentRack.channel >= number
          ? patch.parentRack.channel
          : number;
    }

    return number;
  }

  @override
  int compareTo(DataPatchModel other) {
    return universe - other.universe;
  }
}

class DataPatchRackAssignment {
  final String rackId;
  final int channel;

  const DataPatchRackAssignment({
    required this.rackId,
    required this.channel,
  });

  bool get isAssigned => channel != 0 && rackId.isNotEmpty;

  const DataPatchRackAssignment.unassigned()
      : rackId = '',
        channel = 0;

  DataPatchRackAssignment copyWith({
    String? rackId,
    int? channel,
  }) {
    return DataPatchRackAssignment(
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

  factory DataPatchRackAssignment.fromMap(Map<String, dynamic> map) {
    return DataPatchRackAssignment(
      rackId: map['rackId'] as String,
      channel: map['channel'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataPatchRackAssignment.fromJson(String source) =>
      DataPatchRackAssignment.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
