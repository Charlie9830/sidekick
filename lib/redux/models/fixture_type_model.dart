import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class FixtureTypeModel extends ModelCollectionMember {
  @override
  final String uid;
  final String originalMake;
  final String originalModel;
  final String name;
  final String shortName;
  final double amps;
  final int maxPiggybacks;
  final bool inUse;

  FixtureTypeModel({
    required this.uid,
    this.originalMake = '',
    this.originalModel = '',
    this.name = '',
    this.shortName = '',
    this.amps = 0.0,
    this.maxPiggybacks = 1,
    this.inUse = false,
  });

  const FixtureTypeModel.blank()
      : uid = "",
        name = "",
        shortName = "",
        originalMake = '',
        originalModel = '',
        amps = 0,
        inUse = false,
        maxPiggybacks = 1;

  bool get canPiggyback => maxPiggybacks != 1;

  FixtureTypeModel copyWith({
    String? uid,
    String? originalMake,
    String? originalModel,
    String? name,
    String? shortName,
    double? amps,
    int? maxPiggybacks,
    bool? inUse,
  }) {
    return FixtureTypeModel(
      uid: uid ?? this.uid,
      originalMake: originalMake ?? this.originalMake,
      originalModel: originalModel ?? this.originalModel,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      amps: amps ?? this.amps,
      maxPiggybacks: maxPiggybacks ?? this.maxPiggybacks,
      inUse: inUse ?? this.inUse,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'originalMake': originalMake,
      'originalModel': originalModel,
      'name': name,
      'shortName': shortName,
      'amps': amps,
      'maxPiggybacks': maxPiggybacks,
      'inUse': inUse,
    };
  }

  factory FixtureTypeModel.fromMap(Map<String, dynamic> map) {
    return FixtureTypeModel(
      uid: map['uid'] ?? '',
      originalMake: map['originalMake'] ?? '',
      originalModel: map['originalModel'] ?? '',
      name: map['name'] ?? '',
      shortName: map['shortName'] ?? '',
      amps: map['amps']?.toDouble() ?? 0.0,
      maxPiggybacks: map['maxPiggybacks']?.toInt() ?? 0,
      inUse: map['inUse'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureTypeModel.fromJson(String source) =>
      FixtureTypeModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'FixtureTypeModel(uid: $uid, name: $name, amps: $amps, maxPiggybacks: $maxPiggybacks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FixtureTypeModel &&
        other.uid == uid &&
        other.name == name &&
        other.amps == amps &&
        other.maxPiggybacks == maxPiggybacks;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        amps.hashCode ^
        maxPiggybacks.hashCode;
  }
}
