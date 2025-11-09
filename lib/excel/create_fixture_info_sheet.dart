import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

const List<String> _headers = [
  "FIXTURE_ID",
  "FIXTURE_NAME",
  "FIXTURE_MODE",
  "UNIVERSE",
  "ADDRESS",
  "LOCATION",
  "POWER_PATCH",
];

void createFixtureInfoSheet({
  required List<FixtureModel> fixtures,
  required Map<String, LocationModel> locations,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required Excel excel,
  required String projectName,
}) async {
  // Keep track of column widths, we will set these to the largest values later.
  final Map<int, int> columnWidths = {};
  updateColumnWidths(int index, dynamic value) {
    if (columnWidths[index] == null) {
      columnWidths[index] = value.toString().length;
      return;
    }

    if (columnWidths[index]! < value.toString().length) {
      columnWidths[index] = value.toString().length;
    }
  }

  final sheet = excel.sheets.values.first;

  // Insert Headers
  int columnIndex = 0;
  for (final header in _headers) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: 0));
    cell.value = TextCellValue(header);
    cell.cellStyle = CellStyle(bold: true);

    updateColumnWidths(columnIndex, header);
    columnIndex++;
  }

  // Insert Contents
  int rowIndex = 1; // Start at 1 because headers are at 0.
  for (final fixture in fixtures) {
    final cellValues = _extractCellValues(
        fixture: fixture,
        locations: locations,
        fixtureTypes: fixtureTypes,
        projectName: projectName);
    sheet.insertRowIterables(cellValues, rowIndex);
    rowIndex++;

    // Update Column Widths.
    int columnIndex = 0;
    for (final value in cellValues) {
      updateColumnWidths(columnIndex, value);
      columnIndex++;
    }
  }

  // Set Column Widths.
  for (final entry in columnWidths.entries) {
    sheet.setColumnWidth(entry.key, entry.value * 1.2);
    columnIndex++;
  }
  return;
}

List<CellValue> _extractCellValues({
  required FixtureModel fixture,
  required Map<String, LocationModel> locations,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required String projectName,
}) {
  return [
    IntCellValue(fixture.fid),
    TextCellValue(fixtureTypes[fixture.typeId]?.shortName ?? ''),
    TextCellValue(fixture.mode),
    IntCellValue(fixture.dmxAddress.universe),
    IntCellValue(fixture.dmxAddress.address),
    TextCellValue(locations[fixture.locationId]?.name ?? ''),
    TextCellValue(fixture.powerPatch),
  ];
}
