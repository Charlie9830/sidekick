import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';

class DataPatchModel extends ModelCollectionMember
    implements Comparable<DataPatchModel> {
  @override
  final String uid;
  final String name;
  final int number;
  final int universe;
  final List<String> fixtureIds;
  final String locationId;
  final bool isSpare;
  final int startsAtFixtureId;
  final int endsAtFixtureId;

  DataPatchModel({
    required this.uid,
    this.name = '',
    this.number = 0,
    this.universe = 0,
    this.fixtureIds = const [],
    required this.locationId,
    this.isSpare = false,
    this.startsAtFixtureId = 0,
    this.endsAtFixtureId = 0,
  });

  String get nameWithUniverse => isSpare ? name : '$name $universeLabel';

  String get universeLabel => 'U$universe';

  DataPatchModel copyWith({
    String? uid,
    String? name,
    int? number,
    int? universe,
    List<String>? fixtureIds,
    String? locationId,
    bool? isSpare,
    int? startsAtFixtureId,
    int? endsAtFixtureId,
  }) {
    return DataPatchModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      number: number ?? this.number,
      universe: universe ?? this.universe,
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
      'number': number,
      'universe': universe,
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
      number: map['number']?.toInt() ?? 0,
      universe: map['universe']?.toInt() ?? 0,
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
    return 'DataPatchModel(uid: $uid, name: $name, number: $number, universe: $universe, fixtureIds: $fixtureIds, locationId: $locationId, isSpare: $isSpare, startsAtFixtureId: $startsAtFixtureId, endsAtFixtureId: $endsAtFixtureId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataPatchModel &&
        other.uid == uid &&
        other.name == name &&
        other.number == number &&
        other.universe == universe &&
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
        number.hashCode ^
        universe.hashCode ^
        fixtureIds.hashCode ^
        locationId.hashCode ^
        isSpare.hashCode ^
        startsAtFixtureId.hashCode ^
        endsAtFixtureId.hashCode;
  }

  @override
  int compareTo(DataPatchModel other) {
    return number - other.number;
  }
}
