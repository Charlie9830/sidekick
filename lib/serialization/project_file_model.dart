// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/extension_methods/to_model_map.dart';
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
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class ProjectFileModel {
  final ProjectFileMetadataModel metadata;
  final List<FixtureModel> fixtures;
  final List<PowerMultiOutletModel> powerMultiOutlets;
  final List<DataMultiModel> dataMultis;
  final List<DataPatchModel> dataPatches;
  final List<LocationModel> locations;
  final List<LoomModel> looms;
  final List<CableModel> cables;
  final int maxSequenceBreak;
  final double balanceTolerance;
  final CableType defaultPowerMulti;
  final List<LoomStockModel> loomStock;
  final List<FixtureTypeModel> fixtureTypes;
  final List<HoistModel> hoists;
  final List<HoistControllerModel> hoistControllers;
  final List<HoistMultiModel> hoistMultis;
  final List<PowerSystemModel> powerSystems;
  final List<PowerFeedModel> powerFeeds;
  final List<PowerRackModel> powerRacks;
  final List<PowerRackTypeModel> powerRackTypes;

  ProjectFileModel({
    required this.metadata,
    required this.fixtures,
    required this.powerMultiOutlets,
    required this.dataMultis,
    required this.dataPatches,
    required this.locations,
    required this.looms,
    required this.cables,
    required this.maxSequenceBreak,
    required this.balanceTolerance,
    required this.defaultPowerMulti,
    required this.loomStock,
    required this.fixtureTypes,
    required this.hoists,
    required this.hoistControllers,
    required this.hoistMultis,
    required this.powerSystems,
    required this.powerFeeds,
    required this.powerRacks,
    required this.powerRackTypes,
  });

  ProjectFileModel copyWith({
    ProjectFileMetadataModel? metadata,
    List<FixtureModel>? fixtures,
    List<PowerMultiOutletModel>? powerMultiOutlets,
    List<DataMultiModel>? dataMultis,
    List<DataPatchModel>? dataPatches,
    List<LocationModel>? locations,
    List<LoomModel>? looms,
    List<CableModel>? cables,
    int? maxSequenceBreak,
    double? balanceTolerance,
    CableType? defaultPowerMulti,
    List<LoomStockModel>? loomStock,
    List<FixtureTypeModel>? fixtureTypes,
    List<HoistModel>? hoists,
    List<HoistControllerModel>? hoistControllers,
    List<HoistMultiModel>? hoistMultis,
    List<PowerSystemModel>? powerSystems,
    List<PowerFeedModel>? powerFeeds,
    List<PowerRackModel>? powerRacks,
    List<PowerRackTypeModel>? powerRackTypes,
  }) {
    return ProjectFileModel(
      metadata: metadata ?? this.metadata,
      fixtures: fixtures ?? this.fixtures,
      powerMultiOutlets: powerMultiOutlets ?? this.powerMultiOutlets,
      dataMultis: dataMultis ?? this.dataMultis,
      dataPatches: dataPatches ?? this.dataPatches,
      locations: locations ?? this.locations,
      looms: looms ?? this.looms,
      cables: cables ?? this.cables,
      maxSequenceBreak: maxSequenceBreak ?? this.maxSequenceBreak,
      balanceTolerance: balanceTolerance ?? this.balanceTolerance,
      defaultPowerMulti: defaultPowerMulti ?? this.defaultPowerMulti,
      loomStock: loomStock ?? this.loomStock,
      fixtureTypes: fixtureTypes ?? this.fixtureTypes,
      hoists: hoists ?? this.hoists,
      hoistControllers: hoistControllers ?? this.hoistControllers,
      hoistMultis: hoistMultis ?? this.hoistMultis,
      powerSystems: powerSystems ?? this.powerSystems,
      powerFeeds: powerFeeds ?? this.powerFeeds,
      powerRacks: powerRacks ?? this.powerRacks,
      powerRackTypes: powerRackTypes ?? this.powerRackTypes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'metadata': metadata.toMap(),
      'fixtures': fixtures.map((x) => x.toMap()).toList(),
      'powerMultiOutlets': powerMultiOutlets.map((x) => x.toMap()).toList(),
      'dataMultis': dataMultis.map((x) => x.toMap()).toList(),
      'dataPatches': dataPatches.map((x) => x.toMap()).toList(),
      'locations': locations.map((x) => x.toMap()).toList(),
      'looms': looms.map((x) => x.toMap()).toList(),
      'cables': cables.map((x) => x.toMap()).toList(),
      'maxSequenceBreak': maxSequenceBreak,
      'balanceTolerance': balanceTolerance,
      'defaultPowerMulti': defaultPowerMulti.name,
      'loomStock': loomStock.map((x) => x.toMap()).toList(),
      'fixtureTypes': fixtureTypes.map((x) => x.toMap()).toList(),
      'hoists': hoists.map((x) => x.toMap()).toList(),
      'hoistControllers': hoistControllers.map((x) => x.toMap()).toList(),
      'hoistMultis': hoistMultis.map((x) => x.toMap()).toList(),
      'powerSystems': powerSystems.map((x) => x.toMap()).toList(),
      'powerFeeds': powerFeeds.map((x) => x.toMap()).toList(),
      'powerRacks': powerRacks.map((x) => x.toMap()).toList(),
      'powerRackTypes': powerRackTypes.map((x) => x.toMap()).toList(),
    };
  }

  factory ProjectFileModel.fromMap(Map<String, dynamic> map) {
    return ProjectFileModel(
      metadata: ProjectFileMetadataModel.fromMap(
          map['metadata'] as Map<String, dynamic>),
      fixtures: List<FixtureModel>.from(
        (map['fixtures'] as List<dynamic>).map<FixtureModel>(
          (x) => FixtureModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      powerMultiOutlets: List<PowerMultiOutletModel>.from(
        (map['powerMultiOutlets'] as List<dynamic>).map<PowerMultiOutletModel>(
          (x) => PowerMultiOutletModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      dataMultis: List<DataMultiModel>.from(
        (map['dataMultis'] as List<dynamic>).map<DataMultiModel>(
          (x) => DataMultiModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      dataPatches: List<DataPatchModel>.from(
        (map['dataPatches'] as List<dynamic>).map<DataPatchModel>(
          (x) => DataPatchModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      locations: List<LocationModel>.from(
        (map['locations'] as List<dynamic>).map<LocationModel>(
          (x) => LocationModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      looms: List<LoomModel>.from(
        (map['looms'] as List<dynamic>).map<LoomModel>(
          (x) => LoomModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      cables: List<CableModel>.from(
        (map['cables'] ?? []).map<CableModel>(
          (x) => CableModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxSequenceBreak: (map['maxSequenceBreak'] ?? 0) as int,
      balanceTolerance: (map['balanceTolerance'] ?? 0.0) as double,
      defaultPowerMulti:
          CableType.values.byName(map['type'] ?? CableType.socapex.name),
      loomStock: List<LoomStockModel>.from(
        (map['loomStock'] ?? []).map<LoomStockModel>(
          (x) => LoomStockModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      fixtureTypes: List<FixtureTypeModel>.from((map['fixtureTypes'] ?? [])
          .map<FixtureTypeModel>(
              (x) => FixtureTypeModel.fromMap(x as Map<String, dynamic>))),
      hoists: List<HoistModel>.from(
        (map['hoists'] ?? []).map<HoistModel>(
          (x) => HoistModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      hoistControllers: List<HoistControllerModel>.from(
        (map['hoistControllers'] ?? []).map<HoistControllerModel>(
          (x) => HoistControllerModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      hoistMultis: List<HoistMultiModel>.from(
        (map['hoistMultis'] ?? []).map<HoistMultiModel>(
          (x) => HoistMultiModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      powerSystems: List<PowerSystemModel>.from((map['powerSystems'] ??
              [const PowerSystemModel.defaultSystem().toMap()])
          .map<PowerSystemModel>(
              (x) => PowerSystemModel.fromMap(x as Map<String, dynamic>))),
      powerFeeds: List<PowerFeedModel>.from((map['powerFeeds'] ?? [])
          .map<PowerFeedModel>(
              (x) => PowerFeedModel.fromMap(x as Map<String, dynamic>))),
      powerRacks: List<PowerRackModel>.from((map['powerRacks'] ?? [])
          .map<PowerRackModel>(
              (x) => PowerRackModel.fromMap(x as Map<String, dynamic>))),
      powerRackTypes: List<PowerRackTypeModel>.from(
          (map['powerRackTypes'] ?? []).map<PowerRackTypeModel>(
              (x) => PowerRackTypeModel.fromMap(x as Map<String, dynamic>))),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectFileModel.fromJson(String source) =>
      ProjectFileModel.fromMap(json.decode(source) as Map<String, dynamic>);

  FixtureState toFixtureState() {
    return FixtureState(
      fixtures: fixtures.toModelMap(),
      powerMultiOutlets: powerMultiOutlets.toModelMap(),
      balanceTolerance: balanceTolerance,
      maxSequenceBreak: maxSequenceBreak,
      locations: locations.toModelMap(),
      dataMultis: dataMultis.toModelMap(),
      dataPatches: dataPatches.toModelMap(),
      looms: looms.toModelMap(),
      fixtureTypes: fixtureTypes.toModelMap(),
      cables: cables.toModelMap(),
      defaultPowerMulti: defaultPowerMulti,
      loomStock: loomStock.toModelMap(),
      hoists: hoists.toModelMap(),
      hoistControllers: hoistControllers.toModelMap(),
      hoistMultis: hoistMultis.toModelMap(),
      powerSystems: powerSystems.toModelMap(),
      powerFeeds: powerFeeds.toModelMap(),
      powerRacks: powerRacks.toModelMap(),
      powerRackTypes: powerRackTypes.toModelMap(),
    );
  }
}
