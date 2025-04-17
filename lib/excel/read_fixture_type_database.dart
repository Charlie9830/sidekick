import 'dart:io';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:excel/excel.dart';

const String _kSheetName = "Master List";
const String _kManufactureColumnHeader = "Manufacture";
const String _kModelColumnHeader = "Model";
const String _kShortNameColumnHeader = "Short Name (Patchinator, IJAP)";
const String _kMaxPiggybacksColumnHeader = "Max 16A Piggybacks";
const String _kPowerDrawColumnHeader = "Power Draw (amps)";

class FixtureTypeDatabaseReadResult {
  final Map<String, FixtureTypeModel> fixtureTypes;
  final String? errorMessage;

  FixtureTypeDatabaseReadResult({
    this.fixtureTypes = const {},
    this.errorMessage,
  });
}

class ColumnIndexes {
  final int manufacture;
  final int model;
  final int shortName;
  final int powerDraw;
  final int maxPiggybacks;

  ColumnIndexes({
    this.manufacture = -1,
    this.maxPiggybacks = -1,
    this.model = -1,
    this.powerDraw = -1,
    this.shortName = -1,
  });

  List<ColumnIndex> get asList => [
        ColumnIndex(_kManufactureColumnHeader, manufacture),
        ColumnIndex(_kModelColumnHeader, model),
        ColumnIndex(_kShortNameColumnHeader, shortName),
        ColumnIndex(_kPowerDrawColumnHeader, powerDraw),
        ColumnIndex(_kMaxPiggybacksColumnHeader, maxPiggybacks),
      ];

  bool get hasInvalidIndexes => asList.any((col) => col.index == -1);
}

class ColumnIndex {
  final String name;
  final int index;

  ColumnIndex(this.name, this.index);
}

Future<FixtureTypeDatabaseReadResult> readFixtureTypeDatabase(
    String path) async {
  try {
    final excel = Excel.decodeBytes(await File(path).readAsBytes());

    if (excel.sheets.containsKey(_kSheetName) == false) {
      return FixtureTypeDatabaseReadResult(
          errorMessage:
              'No Excel sheet matching the name \'Master List\' found.');
    }

    final sheet = excel.sheets[_kSheetName]!;

    final headerRowIndex = sheet.rows.indexWhere((row) =>
        row.isNotEmpty &&
        row.first?.value?.toString() == _kManufactureColumnHeader);

    if (headerRowIndex == -1) {
      return FixtureTypeDatabaseReadResult(
          errorMessage:
              "Unable to detect start of Table. Could not find the first column header '$_kManufactureColumnHeader'.");
    }

    final headerRowData = sheet.row(headerRowIndex);

    final columnIndexes = ColumnIndexes(
      manufacture: headerRowData.indexWhere(
          (data) => data?.value.toString() == _kManufactureColumnHeader),
      model: headerRowData
          .indexWhere((data) => data?.value.toString() == _kModelColumnHeader),
      maxPiggybacks: headerRowData.indexWhere(
          (data) => data?.value.toString() == _kMaxPiggybacksColumnHeader),
      powerDraw: headerRowData.indexWhere(
          (data) => data?.value.toString() == _kPowerDrawColumnHeader),
      shortName: headerRowData.indexWhere(
          (data) => data?.value.toString() == _kShortNameColumnHeader),
    );

    if (columnIndexes.hasInvalidIndexes) {
      return FixtureTypeDatabaseReadResult(
          errorMessage:
              'Unable to detect all or some columns. Missing columns: ${columnIndexes.asList.where((col) => col.index == -1).map((col) => col.name).join(', ')}');
    }

    final dataRows = sheet.rows.sublist(headerRowIndex + 1);

    if (dataRows.isEmpty) {
      return FixtureTypeDatabaseReadResult(
          errorMessage: 'No Table entries found.');
    }

    final Set<String> previouslyImportedModels = {};
    final List<FixtureTypeModel> fixtureTypes = [];

    for (final (index, cells) in dataRows.indexed) {
      // Gather Cell Values.
      final String? manufacturer =
          cells.elementAtOrNull(columnIndexes.manufacture)?.value.toString();
      final String? model =
          cells.elementAtOrNull(columnIndexes.model)?.value.toString();
      String? shortName =
          cells.elementAtOrNull(columnIndexes.shortName)?.value.toString();
      String? maxPiggybacks =
          cells.elementAtOrNull(columnIndexes.maxPiggybacks)?.value.toString();
      String? powerDraw =
          cells.elementAtOrNull(columnIndexes.powerDraw)?.value.toString();

      if (_isNullOrEmpty(manufacturer) &&
          _isNullOrEmpty(model) &&
          _isNullOrEmpty(shortName) &&
          _isNullOrEmpty(maxPiggybacks) &&
          _isNullOrEmpty(powerDraw)) {
        // Either an entirely blank row or the end of the data.
        continue;
      }

      // Check for critical Errors.
      if (manufacturer == null) {
        return FixtureTypeDatabaseReadResult(
            errorMessage:
                "Missing data in $_kManufactureColumnHeader column at row ${index + headerRowIndex + 2}");
      }

      if (model == null) {
        return FixtureTypeDatabaseReadResult(
            errorMessage:
                "Missing data in $_kModelColumnHeader column at row ${index + headerRowIndex + 2}");
      }

      if (powerDraw == null) {
        return FixtureTypeDatabaseReadResult(
            errorMessage:
                "Missing data in $_kPowerDrawColumnHeader column at row ${index + headerRowIndex + 2}");
      }

      // These values can just be asserted to default values safely.
      shortName ??= model;
      maxPiggybacks ??= '1';

      // Check that we aren't importing duplicate models (Manufacture and Model data gets duplicated in the excel)
      if (previouslyImportedModels
          .contains(_concatMakeAndModel(manufacturer, model))) {
        continue;
      }

      previouslyImportedModels.add(_concatMakeAndModel(manufacturer, model));

      // Ensure we can correctly parse powerDraw to a number. It's a critical error if we cannot.
      final double? amps = double.tryParse(powerDraw);

      if (amps == null) {
        return FixtureTypeDatabaseReadResult(
            errorMessage:
                "Could not parse amps value to number. Original value: '$powerDraw'");
      }

      fixtureTypes.add(FixtureTypeModel(
        uid: _convertMakeAndModelToUid(manufacturer, model),
        amps: amps,
        maxPiggybacks: int.tryParse(maxPiggybacks.trim()) ?? 1,
        name: _concatMakeAndModel(manufacturer, model),
        shortName: shortName,
        originalShortName: shortName,
        originalMake: manufacturer,
        originalModel: model,
      ));
    }

    return FixtureTypeDatabaseReadResult(
      fixtureTypes: fixtureTypes.toModelMap(),
    );
  } on UnsupportedError {
    return FixtureTypeDatabaseReadResult(
        errorMessage: "Unable to decode Excel file");
  }
}

String _concatMakeAndModel(String manufacturer, String model) {
  return '$manufacturer $model'.trim();
}

bool _isNullOrEmpty(String? value) {
  return value == null || value.isEmpty;
}

String _convertMakeAndModelToUid(String manufacturer, String model) {
  return '${manufacturer.trim()}-${model.trim()}'.toLowerCase();
}
