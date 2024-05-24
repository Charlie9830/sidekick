import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class FixtureState {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final Map<String, PowerMultiOutletModel> powerMultiOutlets;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, DataPatchModel> dataPatches;
  final List<PowerOutletModel> outlets;
  final double balanceTolerance;
  final int maxSequenceBreak;

  FixtureState({
    required this.fixtures,
    required this.outlets,
    required this.powerMultiOutlets,
    required this.balanceTolerance,
    required this.maxSequenceBreak,
    required this.locations,
    required this.dataMultis,
    required this.dataPatches,
  });

  FixtureState.initial()
      : fixtures = {},
        locations = {},
        powerMultiOutlets = {},
        outlets = [],
        balanceTolerance = 0.05, // 5% Balance Tolerance.
        maxSequenceBreak = 4,
        dataMultis = {},
        dataPatches = {};

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    Map<String, LocationModel>? locations,
    Map<String, PowerMultiOutletModel>? powerMultiOutlets,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, DataPatchModel>? dataPatches,
    List<PowerOutletModel>? outlets,
    double? balanceTolerance,
    int? maxSequenceBreak,
  }) {
    return FixtureState(
      fixtures: fixtures ?? this.fixtures,
      locations: locations ?? this.locations,
      powerMultiOutlets: powerMultiOutlets ?? this.powerMultiOutlets,
      dataMultis: dataMultis ?? this.dataMultis,
      dataPatches: dataPatches ?? this.dataPatches,
      outlets: outlets ?? this.outlets,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
    );
  }
}
