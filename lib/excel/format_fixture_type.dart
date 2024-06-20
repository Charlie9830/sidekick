import 'package:sidekick/redux/models/fixture_model.dart';

String formatFixtureType(List<FixtureModel> fixtures) {
  if (fixtures.isEmpty) {
    return '';
  }

  if (fixtures.length == 1) {
    return fixtures.first.type.shortName.trim();
  }

  return '${fixtures.first.type.shortName.trim()} x${fixtures.length}';
}
