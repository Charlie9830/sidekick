import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/excel/excel_columns.dart';
import 'package:sidekick/excel/extract_data_rows.dart';
import 'package:sidekick/excel/extract_text_value.dart';
import 'package:sidekick/excel/input_format_error.dart';
import 'package:sidekick/excel/read_fixtures_patch_data.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

List<FixtureTypeMapping> readFixtureTypes(
    {required Excel document,
    required String sheetName,
    required Map<String, FixtureTypeModel> fixtureTypes}) {
  final sheet = document.sheets[sheetName]!;

  final columnOffset = ExcelColumns.getColumnIndex(ExcelColumnName.fixtureType);

  final dataRows = extractDataRows(sheet, kDataOffset);

  if (dataRows.isEmpty) {
    throw InputFormatError(
        message: 'No data detected in data rows.', rowNumber: kDataOffset);
  }

  final rawFixtureTypeDataSet = dataRows.mapIndexed((index, row) {
    if (row.length < columnOffset) {
      throw InputFormatError(
          message:
              'Numbers of cells in row was found to be less then given Column offset',
          rowNumber: index + kDataOffset);
    }

    final cellValue = extractTextValue(row[columnOffset]);

    if (cellValue.isEmpty) {
      throw InputFormatError(
        message:
            'No Fixture type data found in cell. Raw data: ${row[columnOffset]?.value}',
        rowNumber: index + kDataOffset,
      );
    }

    return cellValue.trim();
  }).toSet();

  return rawFixtureTypeDataSet
      .map((fixtureTypeId) => FixtureTypeMapping(
          sourceName: fixtureTypeId, fixtureTypeId: fixtureTypeId))
      .toList();
}

class FixtureTypeMapping {
  final String sourceName;
  final String fixtureTypeId;

  FixtureTypeMapping({
    required this.sourceName,
    required this.fixtureTypeId,
  });

  bool get isValid => fixtureTypeId.isNotEmpty;
}
