import 'dart:convert';

import 'package:flutter/foundation.dart';

class DataPatchModel {
  final String uid;
  final String name;
  final int universe;
  final String multiId;
  final List<String> fixtureIds;
  final String locationId;
  final bool isSpare;
  final int startsAtFixtureId;
  final int endsAtFixtureId;

  DataPatchModel({
    required this.uid,
    required this.name,
    required this.universe,
    required this.multiId,
    required this.fixtureIds,
    required this.locationId,
    this.isSpare = false,
    required this.startsAtFixtureId,
    required this.endsAtFixtureId,
  });

  String get nameWithUniverse => isSpare ? name : '$name U$universe';

  DataPatchModel copyWith({
    String? uid,
    String? name,
    int? universe,
    String? multiId,
    List<String>? fixtureIds,
    String? locationId,
    bool? isSpare,
    int? startsAtFixtureId,
    int? endsAtFixtureId,
  }) {
    return DataPatchModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      universe: universe ?? this.universe,
      multiId: multiId ?? this.multiId,
      fixtureIds: fixtureIds ?? this.fixtureIds,
      locationId: locationId ?? this.locationId,
      isSpare: isSpare ?? this.isSpare,
      startsAtFixtureId: startsAtFixtureId ?? this.startsAtFixtureId,
      endsAtFixtureId: endsAtFixtureId ?? this.endsAtFixtureId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'universe': universe,
      'multiId': multiId,
      'fixtureIds': fixtureIds,
      'locationId': locationId,
      'isSpare': isSpare,
      'startsAtFixtureId': startsAtFixtureId,
      'endsAtFixtureId': endsAtFixtureId,
    };
  }

  factory DataPatchModel.fromMap(Map<String, dynamic> map) {
    return DataPatchModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      universe: map['universe']?.toInt() ?? 0,
      multiId: map['multiId'] ?? '',
      fixtureIds: List<String>.from(map['fixtureIds']),
      locationId: map['locationId'] ?? '',
      isSpare: map['isSpare'] ?? false,
      startsAtFixtureId: map['startsAtFixtureId']?.toInt() ?? 0,
      endsAtFixtureId: map['endsAtFixtureId']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataPatchModel.fromJson(String source) =>
      DataPatchModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataPatchModel(uid: $uid, name: $name, universe: $universe, multiId: $multiId, fixtureIds: $fixtureIds, locationId: $locationId, isSpare: $isSpare, startsAtFixtureId: $startsAtFixtureId, endsAtFixtureId: $endsAtFixtureId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataPatchModel &&
        other.uid == uid &&
        other.name == name &&
        other.universe == universe &&
        other.multiId == multiId &&
        listEquals(other.fixtureIds, fixtureIds) &&
        other.locationId == locationId &&
        other.isSpare == isSpare &&
        other.startsAtFixtureId == startsAtFixtureId &&
        other.endsAtFixtureId == endsAtFixtureId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        universe.hashCode ^
        multiId.hashCode ^
        fixtureIds.hashCode ^
        locationId.hashCode ^
        isSpare.hashCode ^
        startsAtFixtureId.hashCode ^
        endsAtFixtureId.hashCode;
  }
}
