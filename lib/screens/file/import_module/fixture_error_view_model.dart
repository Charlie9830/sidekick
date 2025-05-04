import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_mapping_errors.dart';

class FixtureErrorViewModel {
  final FixtureMappingError error;
  final int fixtureId;

  FixtureErrorViewModel({
    required this.error,
    required this.fixtureId,
  });
}
