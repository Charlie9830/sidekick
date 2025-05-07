// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
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
  final Map<String, CableModel> cables;
  final double balanceTolerance;
  final int maxSequenceBreak;
  final bool honorDataSpans;
  final CableType defaultPowerMulti;
  final Map<String, LoomStockModel> loomStock;

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
    required this.cables,
    required this.defaultPowerMulti,
    required this.loomStock,
  });

  const FixtureState.initial()
      : fixtures = const {},
        locations = const {},
        powerMultiOutlets = const {},
        outlets = const [],
        balanceTolerance = 0.05, // 5% Balance Tolerance.
        maxSequenceBreak = 4,
        dataMultis = const {},
        dataPatches = const {},
        looms = const {},
        fixtureTypes = const {},
        honorDataSpans = false,
        cables = const {},
        defaultPowerMulti = CableType.socapex,
        loomStock = const {};

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    Map<String, LocationModel>? locations,
    Map<String, FixtureTypeModel>? fixtureTypes,
    Map<String, PowerMultiOutletModel>? powerMultiOutlets,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, DataPatchModel>? dataPatches,
    List<PowerOutletModel>? outlets,
    Map<String, LoomModel>? looms,
    Map<String, CableModel>? cables,
    double? balanceTolerance,
    int? maxSequenceBreak,
    bool? honorDataSpans,
    CableType? defaultPowerMulti,
    Map<String, LoomStockModel>? loomStock,
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
      cables: cables ?? this.cables,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      honorDataSpans: honorDataSpans ?? this.honorDataSpans,
      defaultPowerMulti: defaultPowerMulti ?? this.defaultPowerMulti,
      loomStock: loomStock ?? this.loomStock,
    );
  }
}
