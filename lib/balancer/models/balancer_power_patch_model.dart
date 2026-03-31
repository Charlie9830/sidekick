// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/balancer/models/balancer_intermediate_fixture_model.dart';

class BalancerPowerPatchModel {
  final List<IntermediateFixtureModel> fixtures;
  final String fixtureTypePoolId;

  BalancerPowerPatchModel({
    this.fixtures = const [],
    required this.fixtureTypePoolId,
  });

  BalancerPowerPatchModel.empty()
      : fixtures = const [],
        fixtureTypePoolId = '';

  bool get isEmpty => fixtures.isEmpty;

  bool get isNotEmpty => fixtures.isNotEmpty;

  double get amps => fixtures
      .map((fixture) => fixture.type.amps)
      .fold(0, (value, element) => value + element);

  BalancerPowerPatchModel copyWith({
    List<IntermediateFixtureModel>? fixtures,
    String? fixtureTypePoolId,
  }) {
    return BalancerPowerPatchModel(
      fixtures: fixtures ?? this.fixtures,
      fixtureTypePoolId: fixtureTypePoolId ?? this.fixtureTypePoolId,
    );
  }
}
