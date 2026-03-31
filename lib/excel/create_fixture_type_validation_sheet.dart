import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/excel/format_fixture_type.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createFixtureTypeValidationSheet({
  required Excel excel,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, FixtureModel> fixtures,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required Map<String, FixtureTypePoolModel> fixtureTypePools,
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
    TextCellValue('Pool Contents'),
  ]);

  for (final fixtureTypeEntry in fixturePatchTypes.entries) {
    sheet.appendRow([
      TextCellValue(fixtureTypeEntry.key),
      DoubleCellValue(fixtureTypeEntry.value),
      TextCellValue(''),
    ]);
  }

  for (final pool in fixtureTypePools.values) {
    sheet.appendRow([
      TextCellValue(pool.name),
      DoubleCellValue(_calculatePoolAmps(pool, fixtureTypes)),
      TextCellValue(_getPoolContents(pool, fixtureTypes))
    ]);
  }
}

String _getPoolContents(
    FixtureTypePoolModel pool, Map<String, FixtureTypeModel> fixtureTypes) {
  return pool.items.values
      .map((item) =>
          '${item.qty}x ${fixtureTypes[item.typeId]?.shortName ?? ''}')
      .join(', ');
}

double _calculatePoolAmps(
    FixtureTypePoolModel pool, Map<String, FixtureTypeModel> fixtureTypes) {
  return pool.items.values.fold<double>(
      0,
      (accum, value) =>
          accum + (value.qty * (fixtureTypes[value.typeId]?.amps ?? 0)));
}
