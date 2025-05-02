import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';

class RawFixtureViewModel {
  final RawFixtureModel sourceFixture;
  final RawLocationModel associatedLocation;
  final FixtureTypeModel associatedFixtureType;

  RawFixtureViewModel({
    required this.sourceFixture,
    required this.associatedFixtureType,
    required this.associatedLocation,
  });
}
