// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class ProjectFileModel {
  final ProjectFileMetadataModel metadata;
  final List<FixtureModel> fixtures;
  final List<PowerMultiOutletModel> powerMultiOutlets;
  final List<PowerOutletModel> outlets;
  final List<DataMultiModel> dataMultis;
  final List<DataPatchModel> dataPatches;
  final List<LocationModel> locations;
  final List<LoomModel> looms;
  final List<CableModel> cables;
  final int maxSequenceBreak;
  final double balanceTolerance;

  ProjectFileModel({
    required this.metadata,
    required this.fixtures,
    required this.balanceTolerance,
    required this.dataMultis,
    required this.dataPatches,
    required this.locations,
    required this.maxSequenceBreak,
    required this.powerMultiOutlets,
    required this.outlets,
    required this.looms,
    required this.cables,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'metadata': metadata.toMap(),
      'fixtures': fixtures.map((x) => x.toMap()).toList(),
      'powerMultiOutlets': powerMultiOutlets.map((x) => x.toMap()).toList(),
      'outlets': outlets.map((x) => x.toMap()).toList(),
      'dataMultis': dataMultis.map((x) => x.toMap()).toList(),
      'dataPatches': dataPatches.map((x) => x.toMap()).toList(),
      'locations': locations.map((x) => x.toMap()).toList(),
      'looms': looms.map((x) => x.toMap()).toList(),
      'cables': cables.map((x) => x.toMap()).toList(),
      'maxSequenceBreak': maxSequenceBreak,
      'balanceTolerance': balanceTolerance,
    };
  }

  factory ProjectFileModel.fromMap(Map<String, dynamic> map) {
    return ProjectFileModel(
      metadata: ProjectFileMetadataModel.fromMap(map['metadata'] as Map<String,dynamic>),
      fixtures: List<FixtureModel>.from((map['fixtures'] as List<dynamic>).map<FixtureModel>((x) => FixtureModel.fromMap(x as Map<String,dynamic>),),),
      powerMultiOutlets: List<PowerMultiOutletModel>.from((map['powerMultiOutlets'] as List<int>).map<PowerMultiOutletModel>((x) => PowerMultiOutletModel.fromMap(x as Map<String,dynamic>),),),
      outlets: List<PowerOutletModel>.from((map['outlets'] as List<int>).map<PowerOutletModel>((x) => PowerOutletModel.fromMap(x as Map<String,dynamic>),),),
      dataMultis: List<DataMultiModel>.from((map['dataMultis'] as List<int>).map<DataMultiModel>((x) => DataMultiModel.fromMap(x as Map<String,dynamic>),),),
      dataPatches: List<DataPatchModel>.from((map['dataPatches'] as List<int>).map<DataPatchModel>((x) => DataPatchModel.fromMap(x as Map<String,dynamic>),),),
      locations: List<LocationModel>.from((map['locations'] as List<int>).map<LocationModel>((x) => LocationModel.fromMap(x as Map<String,dynamic>),),),
      looms: List<LoomModel>.from((map['looms'] as List<int>).map<LoomModel>((x) => LoomModel.fromMap(x as Map<String,dynamic>),),),
      cables: List<CableModel>.from((map['cables'] as List<int>).map<CableModel>((x) => CableModel.fromMap(x as Map<String,dynamic>),),),
      maxSequenceBreak: (map['maxSequenceBreak'] ?? 0) as int,
      balanceTolerance: (map['balanceTolerance'] ?? 0.0) as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectFileModel.fromJson(String source) => ProjectFileModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
