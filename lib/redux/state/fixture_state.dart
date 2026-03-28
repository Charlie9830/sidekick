// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/built_in_data_rack_types.dart';
import 'package:sidekick/redux/models/built_in_power_rack_types.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/data_rack_type_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';

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
  final Map<String, PowerFeedModel> powerFeeds;
  final Map<String, PowerRackModel> powerRacks;
  final Map<String, PowerRackTypeModel> powerRackTypes;
  final Map<String, DataRackModel> dataRacks;
  final Map<String, DataRackTypeModel> dataRackTypes;
  final Map<String, FixtureTypePoolModel> fixtureTypePools;

  FixtureState({
    required this.fixtures,
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
    required this.powerFeeds,
    required this.powerRacks,
    required this.powerRackTypes,
    required this.dataRackTypes,
    required this.dataRacks,
    required this.fixtureTypePools,
  });

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
        fixtureTypePools = const {},
        powerFeeds = const {
          PowerFeedModel.kDefaultPowerFeedId: PowerFeedModel.defaultFeed(),
        },
        powerRacks = const {},
        powerRackTypes = BuiltInPowerRackTypes.types,
        dataRackTypes = BuiltInDataRackTypes.types,
        dataRacks = const {};

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
    Map<String, PowerFeedModel>? powerFeeds,
    Map<String, PowerRackModel>? powerRacks,
    Map<String, PowerRackTypeModel>? powerRackTypes,
    Map<String, DataRackModel>? dataRacks,
    Map<String, DataRackTypeModel>? dataRackTypes,
    Map<String, FixtureTypePoolModel>? fixtureTypePools,
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
      powerFeeds: powerFeeds ?? this.powerFeeds,
      powerRacks: powerRacks ?? this.powerRacks,
      powerRackTypes: powerRackTypes ?? this.powerRackTypes,
      dataRacks: dataRacks ?? this.dataRacks,
      dataRackTypes: dataRackTypes ?? this.dataRackTypes,
      fixtureTypePools: fixtureTypePools ?? this.fixtureTypePools,
    );
  }
}
