// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class LocationOverrideModel {
  final OptionalInt maxSequenceBreak;
  final Map<String, int> maxPairings;

  LocationOverrideModel({
    this.maxPairings = const {},
    this.maxSequenceBreak = const OptionalInt.unset(),
  });

  const LocationOverrideModel.none()
      : maxPairings = const {},
        maxSequenceBreak = const OptionalInt.unset();

  bool get hasOverrides =>
      maxSequenceBreak != const LocationOverrideModel.none().maxSequenceBreak &&
      maxPairings.isNotEmpty;

  int getMaxPairings({required String typeId, required int valueIfAbsent}) {
    return maxPairings[typeId] ?? valueIfAbsent;
  }

  LocationOverrideModel copyWith({
    OptionalInt? maxSequenceBreak,
    Map<String, int>? maxPairings,
  }) {
    return LocationOverrideModel(
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      maxPairings: maxPairings ?? this.maxPairings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxSequenceBreak': maxSequenceBreak.toMap(),
      'maxPairings': maxPairings,
    };
  }

  factory LocationOverrideModel.fromMap(Map<String, dynamic> map) {
    return LocationOverrideModel(
      maxSequenceBreak:
          OptionalInt.fromMap(map['maxSequenceBreak'] as Map<String, dynamic>),
      maxPairings: Map<String, int>.from((map['maxPairings'] ??
          const <Map<String, int>>{}) as Map<String, int>),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationOverrideModel.fromJson(String source) =>
      LocationOverrideModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

// Encapulsating class intended to handle the value being null. Essentially a serializable version of an Optional value from the Quiver package.
class OptionalInt {
  final int? value;

  OptionalInt(this.value);

  const OptionalInt.unset() : value = null;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
    };
  }

  factory OptionalInt.fromMap(Map<String, dynamic> map) {
    return OptionalInt(
      map['value'] != null ? map['value'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OptionalInt.fromJson(String source) =>
      OptionalInt.fromMap(json.decode(source) as Map<String, dynamic>);
}
