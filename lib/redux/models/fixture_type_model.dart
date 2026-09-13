// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/wiring_object_model.dart';

class FixtureTypeModel extends ModelCollectionMember {
  @override
  final String uid;
  final String make;
  final String model;
  final String name;
  final String shortName;
  final double amps;
  final int maxPiggybacks;

  /// The fixture type's electrical connection points.
  ///
  /// Captured from GDTF data on MVR import, otherwise
  /// [WiringObjectModel.defaultWiringObjects].
  final List<WiringObjectModel> wiringObjects;

  FixtureTypeModel({
    required this.uid,
    this.make = '',
    this.model = '',
    this.name = '',
    this.shortName = '',
    this.amps = 0.0,
    this.maxPiggybacks = 1,
    this.wiringObjects = WiringObjectModel.defaultWiringObjects,
  });

  const FixtureTypeModel.blank()
    : uid = "",
      name = "",
      shortName = "",
      make = '',
      model = '',
      amps = 0,
      maxPiggybacks = 1,
      wiringObjects = WiringObjectModel.defaultWiringObjects;

  bool get canPiggyback => maxPiggybacks != 1;

  FixtureTypeModel copyWith({
    String? uid,
    String? make,
    String? model,
    String? name,
    String? shortName,
    double? amps,
    int? maxPiggybacks,
    List<WiringObjectModel>? wiringObjects,
  }) {
    return FixtureTypeModel(
      uid: uid ?? this.uid,
      make: make ?? this.make,
      model: model ?? this.model,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      amps: amps ?? this.amps,
      maxPiggybacks: maxPiggybacks ?? this.maxPiggybacks,
      wiringObjects: wiringObjects ?? this.wiringObjects,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'make': make,
      'model': model,
      'name': name,
      'shortName': shortName,
      'amps': amps,
      'maxPiggybacks': maxPiggybacks,
      'wiringObjects': wiringObjects.map((object) => object.toMap()).toList(),
    };
  }

  factory FixtureTypeModel.fromMap(Map<String, dynamic> map) {
    final wiringObjects = [
      for (final object in (map['wiringObjects'] ?? []) as List<dynamic>)
        if (object is Map<String, dynamic>) WiringObjectModel.fromMap(object),
    ];

    return FixtureTypeModel(
      uid: (map['uid'] ?? '') as String,
      make: (map['make'] ?? '') as String,
      model: (map['model'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      shortName: (map['shortName'] ?? '') as String,
      amps: (map['amps'] ?? 0.0) as double,
      maxPiggybacks: (map['maxPiggybacks'] ?? 0) as int,
      // Files saved before wiring capture have no entry; treat them as
      // having no GDTF wiring data.
      wiringObjects: wiringObjects.isEmpty
          ? WiringObjectModel.defaultWiringObjects
          : wiringObjects,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureTypeModel.fromJson(String source) =>
      FixtureTypeModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
