import 'dart:convert';

import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class ProjectFileModel {
  final ProjectFileMetadataModel metadata;
  final List<FixtureModel> fixtures;
  final List<FixtureTypeModel> fixtureTypes;
  final List<PowerMultiOutletModel> powerMultiOutlets;
  final List<PowerOutletModel> outlets;
  final List<DataMultiModel> dataMultis;
  final List<DataPatchModel> dataPatches;
  final List<LocationModel> locations;
  final List<LoomModel> looms;
  final int maxSequenceBreak;
  final double balanceTolerance;

  ProjectFileModel({
    required this.metadata,
    required this.fixtures,
    required this.fixtureTypes,
    required this.balanceTolerance,
    required this.dataMultis,
    required this.dataPatches,
    required this.locations,
    required this.maxSequenceBreak,
    required this.powerMultiOutlets,
    required this.outlets,
    required this.looms,
  });

  Map<String, dynamic> toMap() {
    return {
      'metadata': metadata.toMap(),
      'fixtures': fixtures.map((x) => x.toMap()).toList(),
      'fixtureTypes': fixtureTypes.map((x) => x.toMap()).toList(),
      'powerMultiOutlets': powerMultiOutlets.map((x) => x.toMap()).toList(),
      'outlets': outlets.map((x) => x.toMap()).toList(),
      'dataMultis': dataMultis.map((x) => x.toMap()).toList(),
      'dataPatches': dataPatches.map((x) => x.toMap()).toList(),
      'locations': locations.map((x) => x.toMap()).toList(),
      'looms': looms.map((x) => x.toMap()).toList(),
      'maxSequenceBreak': maxSequenceBreak,
      'balanceTolerance': balanceTolerance,
    };
  }

  factory ProjectFileModel.fromMap(Map<String, dynamic> map) {
    return ProjectFileModel(
      metadata: ProjectFileMetadataModel.fromMap(map['metadata']),
      fixtures: List<FixtureModel>.from(map['fixtures']?.map((x) => FixtureModel.fromMap(x))),
      fixtureTypes: List<FixtureTypeModel>.from(map['fixtureTypes']?.map((x) => FixtureTypeModel.fromMap(x))),
      powerMultiOutlets: List<PowerMultiOutletModel>.from(map['powerMultiOutlets']?.map((x) => PowerMultiOutletModel.fromMap(x))),
      outlets: List<PowerOutletModel>.from(map['outlets']?.map((x) => PowerOutletModel.fromMap(x))),
      dataMultis: List<DataMultiModel>.from(map['dataMultis']?.map((x) => DataMultiModel.fromMap(x))),
      dataPatches: List<DataPatchModel>.from(map['dataPatches']?.map((x) => DataPatchModel.fromMap(x))),
      locations: List<LocationModel>.from(map['locations']?.map((x) => LocationModel.fromMap(x))),
      looms: List<LoomModel>.from(map['looms']?.map((x) => LoomModel.fromMap(x))),
      maxSequenceBreak: map['maxSequenceBreak']?.toInt() ?? 0,
      balanceTolerance: map['balanceTolerance']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectFileModel.fromJson(String source) =>
      ProjectFileModel.fromMap(json.decode(source));
}
