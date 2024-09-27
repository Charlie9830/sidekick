import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

String formatFixtureType(
    List<FixtureModel> fixtures, Map<String, FixtureTypeModel> fixtureTypes) {
  if (fixtures.isEmpty) {
    return '';
  }

  if (fixtures.length == 1) {
    return fixtureTypes[fixtures.first.typeId]?.shortName ?? '';
  }

  return '${fixtureTypes[fixtures.first.typeId]?.shortName ?? ''} x${fixtures.length}';
}
