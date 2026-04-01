import 'package:sidekick/balancer/models/balancer_intermediate_fixture_model.dart';

class PatchContents {
  final List<IntermediateFixtureModel> fixtures;
  final String fixtureTypePoolId;

  PatchContents({
    this.fixtures = const [],
    required this.fixtureTypePoolId,
  });

  factory PatchContents.empty() {
    return PatchContents(fixtureTypePoolId: '', fixtures: []);
  }

  bool get isEmpty => fixtures.isEmpty;

  bool get isNotEmpty => fixtures.isNotEmpty;

  double get amps => fixtures
      .map((fixture) => fixture.type.amps)
      .fold(0, (value, element) => value + element);

  PatchContents copyWith({
    List<IntermediateFixtureModel>? fixtures,
    String? fixtureTypePoolId,
  }) {
    return PatchContents(
      fixtures: fixtures ?? this.fixtures,
      fixtureTypePoolId: fixtureTypePoolId ?? this.fixtureTypePoolId,
    );
  }
}
