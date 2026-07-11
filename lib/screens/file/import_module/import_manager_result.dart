import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';

class ImportManagerResult {
  final List<FixtureModel> fixtures;
  final List<LocationModel> locations;
  final List<FixtureTypeModel> fixtureTypes;
  final List<TrussModel> trusses;
  final List<FixtureGeometryModel> fixtureGeometries;

  ImportManagerResult({
    required this.fixtures,
    required this.locations,
    required this.fixtureTypes,
    this.trusses = const [],
    this.fixtureGeometries = const [],
  });
}
