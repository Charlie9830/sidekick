import 'package:sidekick/screens/file/import_module/map_fixture_types.dart';

class FixtureMappingViewModel {
  final FixtureMappingModel mapping;
  final bool existsInDatabase;

  FixtureMappingViewModel({
    required this.mapping,
    required this.existsInDatabase,
  });
}
