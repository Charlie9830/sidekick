import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class FixtureState {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final Map<String, PowerMultiOutletModel> powerMultiOutlets;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, DataPatchModel> dataPatches;
  final List<PowerOutletModel> outlets;
  final Map<String, LoomModel> looms;
  final double balanceTolerance;
  final int maxSequenceBreak;
  final bool honorDataSpans;

  FixtureState({
    required this.fixtures,
    required this.outlets,
    required this.powerMultiOutlets,
    required this.balanceTolerance,
    required this.maxSequenceBreak,
    required this.locations,
    required this.dataMultis,
    required this.dataPatches,
    required this.looms,
    required this.fixtureTypes,
    required this.honorDataSpans,
  });

  FixtureState.initial()
      : fixtures = {},
        locations = {},
        powerMultiOutlets = {},
        outlets = [],
        balanceTolerance = 0.05, // 5% Balance Tolerance.
        maxSequenceBreak = 4,
        dataMultis = {},
        dataPatches = {},
        looms = {},
        fixtureTypes = {},
        honorDataSpans = false;

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    Map<String, LocationModel>? locations,
    Map<String, FixtureTypeModel>? fixtureTypes,
    Map<String, PowerMultiOutletModel>? powerMultiOutlets,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, DataPatchModel>? dataPatches,
    List<PowerOutletModel>? outlets,
    Map<String, LoomModel>? looms,
    double? balanceTolerance,
    int? maxSequenceBreak,
    bool? honorDataSpans,
  }) {
    return FixtureState(
      fixtures: fixtures ?? this.fixtures,
      locations: locations ?? this.locations,
      fixtureTypes: fixtureTypes ?? this.fixtureTypes,
      powerMultiOutlets: powerMultiOutlets ?? this.powerMultiOutlets,
      dataMultis: dataMultis ?? this.dataMultis,
      dataPatches: dataPatches ?? this.dataPatches,
      outlets: outlets ?? this.outlets,
      looms: looms ?? this.looms,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      honorDataSpans: honorDataSpans ?? this.honorDataSpans,
    );
  }
}
