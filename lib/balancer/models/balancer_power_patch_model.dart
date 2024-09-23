import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/fixture_model.dart';

class BalancerPowerPatchModel {
  final List<FixtureModel> fixtures;

  BalancerPowerPatchModel({
    this.fixtures = const [],
  });

  BalancerPowerPatchModel.empty() : fixtures = const [];

  bool get isEmpty => fixtures.isEmpty;

  bool get isNotEmpty => fixtures.isNotEmpty;

  double get amps => fixtures
      .map((fixture) => fixture.type.amps)
      .fold(0, (value, element) => value + element);

  BalancerPowerPatchModel copyWith({
    List<FixtureModel>? fixtures,
  }) {
    return BalancerPowerPatchModel(
      fixtures: fixtures ?? this.fixtures,
    );
  }

  int compareByFid(BalancerPowerPatchModel other) {
    const maxInt = 0x7FFFFFFFFFFFFFFF;

    final a = fixtures.isEmpty ? maxInt : fixtures.first.fid;
    final b = other.fixtures.isEmpty ? maxInt : other.fixtures.first.fid;

    return a - b;
  }

  int compareBySequence(BalancerPowerPatchModel other) {
    const maxInt = 0x7FFFFFFFFFFFFFFF;

    final a = fixtures.isEmpty ? maxInt : fixtures.first.sequence;
    final b = other.fixtures.isEmpty ? maxInt : other.fixtures.first.sequence;

    return a - b;
  }
}
