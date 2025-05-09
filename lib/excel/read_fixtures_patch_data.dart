import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/excel/excel_columns.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/utils/get_uid.dart';

class FixturesDataReadResult {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final Set<String> inUseTypeIds;
  final String? errorMessage;

  FixturesDataReadResult({
    this.fixtures = const {},
    this.locations = const {},
    this.errorMessage,
    this.inUseTypeIds = const {},
  });
}

const int kDataOffset = 1;

Future<FixturesDataReadResult> readFixturesPatchData({
  required String path,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required String? patchSheetName,
}) async {
  final file = File(path);

  if (await file.exists() == false) {
    return FixturesDataReadResult(
        errorMessage: 'Fixture Patch data could not be located at $path.');
  }

  final fileContents = await file.readAsBytes();

  try {
    final excel = Excel.decodeBytes(fileContents);

    Sheet sheet;

    if (excel.sheets.length == 1) {
      if (patchSheetName != null &&
          excel.sheets.values.first.sheetName != patchSheetName) {
        return FixturesDataReadResult(
            errorMessage:
                "Unable to find a sheet named $patchSheetName in Excel document.\nExisting sheet is named '${excel.sheets.values.first.sheetName}'");
      }

      sheet = excel.sheets.values.first;
    } else {
      if (patchSheetName == null) {
        return FixturesDataReadResult(
            errorMessage:
                'Multiple Sheets detected in Excel. You must provide a sheet name.\nAvailable Options: [ ${excel.sheets.values.map((sheet) => sheet.sheetName).join(', ')} ]');
      }

      if (excel.sheets.containsKey(patchSheetName) == false) {
        return FixturesDataReadResult(
            errorMessage:
                "Unable to find a sheet matching the name '$patchSheetName'.\nAvailable Options: [ ${excel.sheets.values.map((sheet) => sheet.sheetName).join(', ')} ] ");
      }

      sheet = excel.sheets[patchSheetName]!;
    }

    final rawDataRows = sheet.rows.sublist(kDataOffset).toList();

    final locationNameMap = _readLocations(rawDataRows);

    final List<FixtureModel> fixtures = [];
    final Set<int> usedFixtureIds = {};
    final Set<String> inUseTypeIds = {};

    // Construct a Map of our Library Fixture Types by their short Name.
    Map<String, FixtureTypeModel> fixtureTypesByOriginalShortName =
        Map<String, FixtureTypeModel>.fromEntries(
            fixtureTypes.values.map((type) => MapEntry(type.shortName, type)));

    for (final (index, row) in rawDataRows.indexed) {
      final (fixtureId, fidError) = _extractFixtureIdCellValue(
          row[ExcelColumns.getColumnIndex(ExcelColumnName.fixtureId)]);

      if (fidError != null) {
        return FixturesDataReadResult(errorMessage: fidError);
      }

      if (usedFixtureIds.contains(fixtureId)) {
        return FixturesDataReadResult(
            errorMessage:
                'Duplicate Fixture number detected, Fixture ID $fixtureId, detected at row ${index + kDataOffset}');
      }

      final (fixtureTypeName, fixtureTypeError) = _extractFixtureTypeCellValue(
          row[ExcelColumns.getColumnIndex(ExcelColumnName.fixtureType)]);

      if (fixtureTypeError != null) {
        return FixturesDataReadResult(errorMessage: fixtureTypeError);
      }

      if (fixtureTypesByOriginalShortName.containsKey(fixtureTypeName) ==
          false) {
        return FixturesDataReadResult(
            errorMessage:
                "Unable to find a matching Fixture type for the fixture type short name value '$fixtureTypeName'"
                "\n"
                "Please ensure the fixture database has a matching entry with the same 'Short Name'.");
      }

      final fixtureType = fixtureTypesByOriginalShortName[fixtureTypeName]!;
      inUseTypeIds.add(fixtureType.uid);

      final String locationId = locationNameMap[_convertRawLocationToString(
                  row[ExcelColumns.getColumnIndex(ExcelColumnName.location)])]
              ?.uid ??
          '';

      final int universe = switch (
          row[ExcelColumns.getColumnIndex(ExcelColumnName.universe)]?.value) {
        TextCellValue v => int.parse(v.value.text?.trim() ?? ""),
        IntCellValue v => v.value,
        _ => 0,
      };

      final int address = switch (
          row[ExcelColumns.getColumnIndex(ExcelColumnName.address)]?.value) {
        TextCellValue v => int.parse(v.value.text?.trim() ?? ""),
        IntCellValue v => v.value,
        _ => 0,
      };

      fixtures.add(FixtureModel(
        uid: getUid(),
        sequence: index + 1,
        fid: fixtureId,
        typeId: fixtureType.uid,
        locationId: locationId,
        dmxAddress: DMXAddressModel(universe: universe, address: address),
      ));
    }

    return FixturesDataReadResult(
      fixtures: fixtures.toModelMap(),
      locations: locationNameMap.values.toModelMap(),
      inUseTypeIds: inUseTypeIds,
    );
  } on UnsupportedError {
    return FixturesDataReadResult(
        errorMessage: 'Unsupported file type. Only .xlsx files are supported.');
  }
}

(String value, String? error) _extractFixtureTypeCellValue(Data? data) {
  if (data == null) {
    return ('', 'Invalid Fixture Type Data.');
  }

  final cell = data.value;
  final rowIndex = data.rowIndex;

  if (cell == null) {
    return ('', 'No Fixture Type data at row $rowIndex');
  }

  if (cell is TextCellValue) {
    String typeData = cell.value.text ?? '';

    if (typeData.isEmpty) {
      return ('', 'Invalid Fixture Type data. Blank cell at row $rowIndex');
    }

    return (typeData.trim(), null);
  }

  return (
    "",
    'Unknown Fixture Type cell value type. Provided Cell Value Type: ${cell.runtimeType}'
  );
}

(int value, String? error) _extractFixtureIdCellValue(Data? data) {
  if (data == null) {
    return (0, 'Invalid Fixture ID Data.');
  }

  final cell = data.value;
  final rowIndex = data.rowIndex;

  if (cell == null) {
    return (0, null);
  }

  if (cell is TextCellValue) {
    final int? fid = int.tryParse(cell.value.text?.trim() ?? '');

    if (fid == null) {
      return (0, null);
    }

    return (fid, null);
  }

  if (cell is IntCellValue) {
    final fid = cell.value;

    if (fid < 1) {
      return (
        0,
        'Invalid Fixture ID data: A Fixture ID cannot be less than 1. Found at row $rowIndex'
      );
    }

    return (fid, null);
  }

  return (
    0,
    'Unknown Fixture ID Cell Value Type. Provided Cell Value Type: ${cell.runtimeType}'
  );
}

///
/// Extracts a map of LocationModels from the provided raw row data.
/// The Map keys reference the location name, not the Uid.
///
Map<String, LocationModel> _readLocations(List<List<Data?>> rows) {
  final locationsSet = rows
      .map((row) => _convertRawLocationToString(row.elementAtOrNull(
          ExcelColumns.getColumnIndex(ExcelColumnName.location))))
      .toSet();

  return Map<String, LocationModel>.fromEntries(locationsSet.map(
      (locationName) => MapEntry(
          locationName,
          LocationModel(
              uid: getUid(),
              name: locationName,
              color: LocationModel.matchColor(locationName),
              multiPrefix: LocationModel.matchMultiPrefix(locationName),
              delimiter:
                  LocationModel.getDefaultDelimiterValue(locationName)))));
}

String _convertRawLocationToString(Data? data) {
  if (data == null) {
    return '';
  }

  return switch (data.value) {
    TextCellValue v => v.value.text?.trim() ?? "",
    IntCellValue v => v.value.toString().trim(),
    DoubleCellValue v => v.value.toString().trim(),
    _ => '',
  };
}
