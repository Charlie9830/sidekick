import 'package:sidekick/enums.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';

class ImportManagerViewModel {
  final ImportManagerStep step;
  final void Function(ImportManagerStep nextStep)? goToStep;
  final void Function(String path) onFixtureDatabaseFilePathChanged;
  final void Function(String path) onFixtureMappingPathChanged;
  final String fixtureDatabaseFilePath;
  final String fixtureMappingFilePath;
  final Map<String, FixtureViewModel> existingFixtureViewModels;
  final Map<String, LocationModel> existingLocations;
  final Map<String, FixtureTypeModel> existingFixtureTypes;
  final Map<String, FixtureModel> existingFixtures;

  ImportManagerViewModel({
    required this.step,
    required this.goToStep,
    required this.onFixtureDatabaseFilePathChanged,
    required this.onFixtureMappingPathChanged,
    required this.fixtureDatabaseFilePath,
    required this.fixtureMappingFilePath,
    required this.existingFixtureViewModels,
    required this.existingLocations,
    required this.existingFixtureTypes,
    required this.existingFixtures,
  });
}
