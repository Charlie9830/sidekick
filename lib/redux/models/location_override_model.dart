// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';

class LocationOverrideModel {
  final OptionalInt maxSequenceBreak;
  final Map<String, int> maxPairings;
  final Set<String> enabledFixtureTypePoolIds;

  /// Breakout cabling overrides, keyed by fixture type id.
  final Map<String, FixtureTypeCablingOverride> cabling;

  LocationOverrideModel({
    this.maxPairings = const {},
    this.maxSequenceBreak = const OptionalInt.unset(),
    this.enabledFixtureTypePoolIds = const {},
    this.cabling = const {},
  });

  const LocationOverrideModel.none()
    : maxPairings = const {},
      maxSequenceBreak = const OptionalInt.unset(),
      enabledFixtureTypePoolIds = const {},
      cabling = const {};

  bool get hasOverrides =>
      maxSequenceBreak != const LocationOverrideModel.none().maxSequenceBreak ||
      maxPairings.isNotEmpty ||
      enabledFixtureTypePoolIds.isNotEmpty ||
      cabling.isNotEmpty;

  int getMaxPairings({required String typeId, required int valueIfAbsent}) {
    return maxPairings[typeId] ?? valueIfAbsent;
  }

  /// The cabling override for [typeId], or an empty one when there is none.
  FixtureTypeCablingOverride getCabling(String typeId) =>
      cabling[typeId] ?? const FixtureTypeCablingOverride.none();

  /// These overrides with [typeId]'s cabling replaced by [override], dropping
  /// the entry altogether when [override] is empty.
  LocationOverrideModel withCabling(
    String typeId,
    FixtureTypeCablingOverride override,
  ) => copyWith(
    cabling: Map.of(cabling)
      ..remove(typeId)
      ..addAll({if (!override.isEmpty) typeId: override}),
  );

  LocationOverrideModel copyWith({
    OptionalInt? maxSequenceBreak,
    Map<String, int>? maxPairings,
    Set<String>? enabledFixtureTypePoolIds,
    Map<String, FixtureTypeCablingOverride>? cabling,
  }) {
    return LocationOverrideModel(
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      maxPairings: maxPairings ?? this.maxPairings,
      enabledFixtureTypePoolIds:
          enabledFixtureTypePoolIds ?? this.enabledFixtureTypePoolIds,
      cabling: cabling ?? this.cabling,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxSequenceBreak': maxSequenceBreak.toMap(),
      'maxPairings': maxPairings,
      'enabledFixtureTypePoolIds': enabledFixtureTypePoolIds.toList(),
      'cabling': {
        for (final MapEntry(:key, :value) in cabling.entries)
          key: value.toMap(),
      },
    };
  }

  factory LocationOverrideModel.fromMap(Map<String, dynamic> map) {
    final raw = LocationOverrideModel(
      maxSequenceBreak: OptionalInt.fromMap(
        map['maxSequenceBreak'] as Map<String, dynamic>,
      ),
      maxPairings: Map<String, int>.from(map['maxPairings'] ?? <String, int>{}),
      enabledFixtureTypePoolIds: Set<String>.from(
        map['enabledFixtureTypePoolIds'] ?? <String>[],
      ),
      cabling: {
        for (final MapEntry(:key, :value)
            in (map['cabling'] as Map<String, dynamic>? ?? {}).entries)
          key: FixtureTypeCablingOverride.fromMap(
            value as Map<String, dynamic>,
          ),
      },
    );

    return raw.maxSequenceBreak.value == null &&
            raw.maxPairings.isEmpty &&
            raw.enabledFixtureTypePoolIds.isEmpty &&
            raw.cabling.isEmpty
        ? const LocationOverrideModel.none()
        : raw;
  }

  String toJson() => json.encode(toMap());

  factory LocationOverrideModel.fromJson(String source) =>
      LocationOverrideModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

// Encapulsating class intended to handle the value being null. Essentially a serializable version of an Optional value from the Quiver package.
class OptionalInt {
  final int? value;

  OptionalInt(this.value);

  const OptionalInt.unset() : value = null;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'value': value};
  }

  factory OptionalInt.fromMap(Map<String, dynamic> map) {
    return OptionalInt(map['value'] != null ? map['value'] as int : null);
  }

  String toJson() => json.encode(toMap());

  factory OptionalInt.fromJson(String source) =>
      OptionalInt.fromMap(json.decode(source) as Map<String, dynamic>);
}
