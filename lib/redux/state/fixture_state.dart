import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class FixtureState {
  final Map<String, FixtureModel> fixtures;
  final List<PowerPatchModel> patches;
  final List<PowerOutletModel> outlets;

  FixtureState(
      {required this.fixtures, required this.patches, required this.outlets});

  FixtureState.initial()
      : fixtures = {},
        patches = [],
        outlets = [];

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    List<PowerPatchModel>? patches,
    List<PowerOutletModel>? outlets,
  }) {
    return FixtureState(
      fixtures: fixtures ?? this.fixtures,
      patches: patches ?? this.patches,
      outlets: outlets ?? this.outlets,
    );
  }
}
