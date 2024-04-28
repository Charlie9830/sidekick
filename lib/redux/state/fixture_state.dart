import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class FixtureState {
  final Map<String, FixtureModel> fixtures;
  final List<PowerPatchModel> patches;
  final List<PowerOutletModel> outlets;
  final double balanceTolerance;
  final int maxSequenceBreak;

  FixtureState({
    required this.fixtures,
    required this.patches,
    required this.outlets,
    required this.balanceTolerance,
    required this.maxSequenceBreak,
  });

  FixtureState.initial()
      : fixtures = {},
        patches = [],
        outlets = [],
        balanceTolerance = 0.05, // 5% Balance Tolerance.
        maxSequenceBreak = 4;

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    List<PowerPatchModel>? patches,
    List<PowerOutletModel>? outlets,
    double? balanceTolerance,
    int? maxSequenceBreak,
  }) {
    return FixtureState(
      fixtures: fixtures ?? this.fixtures,
      patches: patches ?? this.patches,
      outlets: outlets ?? this.outlets,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
    );
  }
}
