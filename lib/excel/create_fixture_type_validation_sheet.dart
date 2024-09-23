import 'package:excel/excel.dart';
import 'package:sidekick/excel/format_fixture_type.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

void createFixtureTypeValidationSheet({
  required Excel excel,
  required Iterable<PowerOutletModel> outlets,
  required Map<String, FixtureModel> fixtures,
}) {
  final sheet = excel['Fixture Types'];

  final fixturePatchTypes = Map<String, double>.fromEntries(outlets.map(
    (outlet) => MapEntry(
      formatFixtureType(outlet.fixtureIds.map((id) => fixtures[id]!).toList()),
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
