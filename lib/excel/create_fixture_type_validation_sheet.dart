import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/excel/format_fixture_type.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createFixtureTypeValidationSheet({
  required Excel excel,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, FixtureModel> fixtures,
  required Map<String, FixtureTypeModel> fixtureTypes,
}) {
  final sheet = excel['Fixture Types'];

  final outlets = powerMultis.values.map((multi) => multi.children).flattened;

  final fixturePatchTypes = Map<String, double>.fromEntries(outlets.map(
    (outlet) => MapEntry(
      formatFixtureType(
          outlet.fixtureIds.map((id) => fixtures[id]!).toList(), fixtureTypes),
      outlet.load,
    ),
  ))
    ..removeWhere((key, value) => key.isEmpty);

  // Header Rows
  sheet.appendRow([
    TextCellValue('Fixture'),
    TextCellValue('Amps'),
  ]);

  for (final fixtureTypeEntry in fixturePatchTypes.entries) {
    sheet.appendRow([
      TextCellValue(fixtureTypeEntry.key),
      DoubleCellValue(fixtureTypeEntry.value)
    ]);
  }
}
