import 'package:excel/excel.dart';
import 'package:sidekick/excel/extract_text_value.dart';
import 'package:sidekick/excel/excel_columns.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';

Iterable<RawRowData> readRawPatchData(Sheet sheet, int dataOffset) sync* {
  for (int i = dataOffset; i <= sheet.rows.length; i++) {
    final rowNumber = i + 1;
    final row = sheet.rows[i];
    RawRowData rawRow = RawRowData(rowNumber: rowNumber);

    // Validate if there is any data within the row.
    // If there is no data at all. We shouldn't proceed trying to read this row.
    if (row.nonNulls.isEmpty) {
      yield rawRow.copyWithError(NoRowDataError());
      continue;
    }

    // Validate that there is at least enough data within the row.
    // If there isn't enough data in the row. We shouldn't proceed trying to read this row.
    if (row.length < ExcelColumns.maxIndex) {
      yield rawRow.copyWithError(MalformedRowError());
      continue;
    }

    // Reduce each of the Rows cell values into a [RowRowData] object and yield it.
    yield ExcelColumnName.values.fold<RawRowData>(
        rawRow,
        (currentRawRow, columnName) => _parseCellValue(
            columnName: columnName,
            rawRow: currentRawRow,
            rawValue:
                row.elementAtOrNull(ExcelColumns.getColumnIndex(columnName))));
  }
}

RawRowData _parseCellValue(
    {required Data? rawValue,
    required RawRowData rawRow,
    required ExcelColumnName columnName}) {
  if (rawValue == null) {
    return rawRow.copyWithError(MissingDataError(
        columnName: ExcelColumns.getHumanFriendlyColumnName(columnName)));
  }

  final valueAsText = extractTextValue(rawValue);

  if (valueAsText.isEmpty) {
    return rawRow.copyWithError(MissingDataError(
        columnName: ExcelColumns.getHumanFriendlyColumnName(columnName)));
  }

  return switch (columnName) {
    ExcelColumnName.fixtureId => rawRow.copyWith(fid: valueAsText),
    ExcelColumnName.fixtureType => rawRow.copyWith(fixtureType: valueAsText),
    ExcelColumnName.location => rawRow.copyWith(location: valueAsText),
    ExcelColumnName.universe => int.tryParse(valueAsText) != null
        ? rawRow.copyWith(universe: int.tryParse(valueAsText))
        : rawRow.copyWithError(InvalidDataTypeError(
            columnName: ExcelColumns.getHumanFriendlyColumnName(columnName),
            data: valueAsText,
            expectedType: int)),
    ExcelColumnName.address => int.tryParse(valueAsText) != null
        ? rawRow.copyWith(address: int.tryParse(valueAsText))
        : rawRow.copyWithError(InvalidDataTypeError(
            columnName: ExcelColumns.getHumanFriendlyColumnName(columnName),
            data: valueAsText,
            expectedType: int)),
    ExcelColumnName.fixtureMode => rawRow,
  };
}
