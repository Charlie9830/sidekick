import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'package:sidekick/redux/models/fixture_model.dart';

class PowerPatchModel {
  final List<FixtureModel> fixtures;

  PowerPatchModel({
    this.fixtures = const [],
  });

  PowerPatchModel.empty() : fixtures = const [];

  bool get isEmpty => fixtures.isEmpty;

  double get amps => fixtures
      .map((fixture) => fixture.type.amps)
      .fold(0, (value, element) => value + element);

  ///
  /// Returns the Maximum allowed Piggybacks of the elements in the [fixtures] list, by returning the
  /// lowest allowed piggybacks ammount.
  ///
  int get maxAllowedPiggybacks {
    if (fixtures.isEmpty) {
      return 1;
    }

    return fixtures
        .map((fixture) => fixture.type.maxPiggybacks)
        .sorted((a, b) => a - b)
        .first;
  }

  PowerPatchModel copyWith({
    List<FixtureModel>? fixtures,
  }) {
    return PowerPatchModel(
      fixtures: fixtures ?? this.fixtures,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fixtures': fixtures.map((x) => x.toMap()).toList(),
    };
  }

  factory PowerPatchModel.fromMap(Map<String, dynamic> map) {
    return PowerPatchModel(
      fixtures: List<FixtureModel>.from(
          map['fixtures']?.map((x) => FixtureModel.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerPatchModel.fromJson(String source) =>
      PowerPatchModel.fromMap(json.decode(source));

  @override
  String toString() => 'PowerPatchModel(fixtures: $fixtures)';
}
