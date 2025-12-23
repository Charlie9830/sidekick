// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';

class FixtureState {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final Map<String, PowerMultiOutletModel> powerMultiOutlets;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, DataPatchModel> dataPatches;
  final Map<String, LoomModel> looms;
  final Map<String, CableModel> cables;
  final double balanceTolerance;
  final int maxSequenceBreak;
  final CableType defaultPowerMulti;
  final Map<String, LoomStockModel> loomStock;
  final Map<String, HoistModel> hoists;
  final Map<String, HoistControllerModel> hoistControllers;
  final Map<String, HoistMultiModel> hoistMultis;
  final Map<String, PowerSystemModel> powerSystems;
  final Map<String, PowerFeedModel> powerFeeds;

  FixtureState(
      {required this.fixtures,
      required this.powerMultiOutlets,
      required this.balanceTolerance,
      required this.maxSequenceBreak,
      required this.locations,
      required this.dataMultis,
      required this.dataPatches,
      required this.looms,
      required this.fixtureTypes,
      required this.cables,
      required this.defaultPowerMulti,
      required this.loomStock,
      required this.hoists,
      required this.hoistControllers,
      required this.hoistMultis,
      required this.powerSystems,
      required this.powerFeeds,
      r});

  const FixtureState.initial()
      : fixtures = const {},
        locations = const {},
        powerMultiOutlets = const {},
        balanceTolerance = 0.05, // 5% Balance Tolerance.
        maxSequenceBreak = 4,
        dataMultis = const {},
        dataPatches = const {},
        looms = const {},
        fixtureTypes = const {},
        cables = const {},
        defaultPowerMulti = CableType.socapex,
        loomStock = const {},
        hoists = const {},
        hoistControllers = const {},
        hoistMultis = const {},
        powerSystems = const {
          PowerSystemModel.kDefaultUid: PowerSystemModel.defaultSystem(),
        },
        powerFeeds = const {};

  FixtureState copyWith({
    Map<String, FixtureModel>? fixtures,
    Map<String, LocationModel>? locations,
    Map<String, FixtureTypeModel>? fixtureTypes,
    Map<String, PowerMultiOutletModel>? powerMultiOutlets,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, DataPatchModel>? dataPatches,
    Map<String, LoomModel>? looms,
    Map<String, CableModel>? cables,
    double? balanceTolerance,
    int? maxSequenceBreak,
    CableType? defaultPowerMulti,
    Map<String, LoomStockModel>? loomStock,
    Map<String, HoistModel>? hoists,
    Map<String, HoistControllerModel>? hoistControllers,
    Map<String, HoistMultiModel>? hoistMultis,
    Map<String, PowerSystemModel>? powerSystems,
    Map<String, PowerFeedModel>? powerFeeds,
  }) {
    return FixtureState(
      fixtures: fixtures ?? this.fixtures,
      locations: locations ?? this.locations,
      fixtureTypes: fixtureTypes ?? this.fixtureTypes,
      powerMultiOutlets: powerMultiOutlets ?? this.powerMultiOutlets,
      dataMultis: dataMultis ?? this.dataMultis,
      dataPatches: dataPatches ?? this.dataPatches,
      looms: looms ?? this.looms,
      cables: cables ?? this.cables,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      defaultPowerMulti: defaultPowerMulti ?? this.defaultPowerMulti,
      loomStock: loomStock ?? this.loomStock,
      hoists: hoists ?? this.hoists,
      hoistControllers: hoistControllers ?? this.hoistControllers,
      hoistMultis: hoistMultis ?? this.hoistMultis,
      powerSystems: powerSystems ?? this.powerSystems,
      powerFeeds: powerFeeds ?? this.powerFeeds,
    );
  }
}
