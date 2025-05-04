import 'package:collection/collection.dart';

enum ExcelColumnName {
  fixtureId,
  fixtureType,
  fixtureMode,
  location,
  universe,
  address,
}

class ExcelColumns {
  static int getColumnIndex(ExcelColumnName name) {
    return switch (name) {
      ExcelColumnName.fixtureId => 0,
      ExcelColumnName.fixtureType => 1,
      ExcelColumnName.fixtureMode => 2,
      ExcelColumnName.location => 3,
      ExcelColumnName.universe => 4,
      ExcelColumnName.address => 5,
    };
  }

  static String getHumanFriendlyColumnName(ExcelColumnName name) {
    return switch (name) {
      ExcelColumnName.fixtureId => "Fixture ID",
      ExcelColumnName.fixtureType => "Fixture Type",
      ExcelColumnName.fixtureMode => "Fixture Mode",
      ExcelColumnName.location => "Location",
      ExcelColumnName.universe => "Universe",
      ExcelColumnName.address => "Address",
    };
  }

  static int maxIndex =
      ExcelColumnName.values.map((name) => getColumnIndex(name)).max;

  // Hidden from Public API until an implementation of dynamic column indexes is properly finished.
  // TODO: Implement a system to detect column indexes dynamically.
  // static int? _detectColumnOffset(Sheet sheet, ExcelColumnName desiredColumn) {
  //   final headerRow = extractHeaderRow(sheet);

  //   return headerRow.nonNulls
  //       .firstWhereOrNull(
  //           (data) => _regexes[desiredColumn]!.hasMatch(extractTextValue(data)))
  //       ?.columnIndex;
  // }

  // static final Map<ExcelColumnName, RegExp> _regexes = {
  //   ExcelColumnName.fixtureType: RegExp(r'FIXTURE_NAME', caseSensitive: false),
  //   ExcelColumnName.fixtureId: RegExp(r'FIXTURE_ID', caseSensitive: false),
  //   ExcelColumnName.fixtureMode: RegExp(r'FIXTURE_MODE', caseSensitive: false),
  //   ExcelColumnName.location: RegExp(r'LOCATION', caseSensitive: false),
  //   ExcelColumnName.universe: RegExp(r'UNIVERSE', caseSensitive: false),
  //   ExcelColumnName.address: RegExp(r'ADDRESS', caseSensitive: false),
  // };
}
