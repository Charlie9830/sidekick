import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/utils/get_uid.dart';

class _FixtureExcelColumns {
  static const int fid = 0;
  static const int fixtureType = 1;
  // static const int fixtureMode = 2;
  static const int location = 3;
  static const int universe = 4;
  static const int address = 5;
}

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

Future<FixturesDataReadResult> readFixturesPatchData({
  required String path,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required String? patchSheetName,
}) async {
  const int kDataOffset = 1;

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
    Map<String, FixtureTypeModel> fixtureTypesByShortName =
        Map<String, FixtureTypeModel>.fromEntries(
            fixtureTypes.values.map((type) => MapEntry(type.shortName, type)));

    for (final (index, row) in rawDataRows.indexed) {
      final (fixtureId, fidError) =
          _extractFixtureIdCellValue(row[_FixtureExcelColumns.fid]);

      if (fidError != null) {
        return FixturesDataReadResult(errorMessage: fidError);
      }

      if (usedFixtureIds.contains(fixtureId)) {
        return FixturesDataReadResult(
            errorMessage:
                'Duplicate Fixture number detected, Fixture ID $fixtureId, detected at row ${index + kDataOffset}');
      }

      final (fixtureTypeName, fixtureTypeError) =
          _extractFixtureTypeCellValue(row[_FixtureExcelColumns.fixtureType]);

      if (fixtureTypeError != null) {
        return FixturesDataReadResult(errorMessage: fixtureTypeError);
      }

      if (fixtureTypesByShortName.containsKey(fixtureTypeName) == false) {
        return FixturesDataReadResult(
            errorMessage:
                "Unable to find a matching Fixture type for the fixture type short name value '$fixtureTypeName'"
                "\n"
                "Please ensure the fixture database has a matching entry with the same 'Short Name'.");
      }

      final fixtureType = fixtureTypesByShortName[fixtureTypeName]!;
      inUseTypeIds.add(fixtureType.uid);

      final String locationId = locationNameMap[_convertRawLocationToString(
                  row[_FixtureExcelColumns.location])]
              ?.uid ??
          '';

      final int universe = switch (row[_FixtureExcelColumns.universe]?.value) {
        TextCellValue v => int.parse(v.value.text?.trim() ?? ""),
        IntCellValue v => v.value,
        _ => 0,
      };

      final int address = switch (row[_FixtureExcelColumns.address]?.value) {
        TextCellValue v => int.parse(v.value.text?.trim() ?? ""),
        IntCellValue v => v.value,
        _ => 0,
      };

      fixtures.add(FixtureModel(
        uid: getUid(),
        sequence: index + 1,
        fid: fixtureId,
        type: fixtureType,
        locationId: locationId,
        dmxAddress: DMXAddressModel(universe: universe, address: address),
      ));
    }

    return FixturesDataReadResult(
      fixtures: convertToModelMap(fixtures),
      locations: convertToModelMap(locationNameMap.values),
      inUseTypeIds: inUseTypeIds,
    );
  } on UnsupportedError catch (e) {
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
    return (0, 'No Fixture Id data at row $rowIndex');
  }

  if (cell is TextCellValue) {
    final int? fid = int.tryParse(cell.value.text?.trim() ?? '');

    if (fid == null) {
      return (0, "Invalid Fixture ID data at row $rowIndex");
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
      .map((row) => _convertRawLocationToString(
          row.elementAtOrNull(_FixtureExcelColumns.location)))
      .toSet();

  return Map<String, LocationModel>.fromEntries(locationsSet.map(
      (locationName) => MapEntry(
          locationName,
          LocationModel(
              uid: getUid(),
              name: locationName,
              color: LocationModel.matchColor(locationName),
              multiPrefix: LocationModel.matchMultiPrefix(locationName)))));
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
