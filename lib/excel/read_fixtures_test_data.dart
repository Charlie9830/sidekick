import 'dart:io';

import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/utils/get_uid.dart';

class _FixtureExcelColumns {
  static const int sequence = 0;
  static const int fid = 1;
  static const int fixtureType = 2;
  static const int location = 3;
}

Future<
        (
          Map<String, FixtureModel> fixtures,
          Map<String, LocationModel> locations
        )>
    readFixturesTestData(
        {required String path,
        required Map<String, FixtureTypeModel> fixtureTypes}) async {
  final file = File(path);

  if (await file.exists() == false) {
    throw "Fixture Data file cannot be found at\n ${file.path}";
  }

  final fileContents = await file.readAsBytes();
  final excel = Excel.decodeBytes(fileContents);

  if (excel.tables.containsKey('Fixtures') == false) {
    throw "Cannot find 'Fixtures' sheet in Data file. At\n ${file.path}";
  }

  final sheet = excel.tables['Fixtures']!;

  final rawDataRows = sheet.rows.sublist(1).toList();

  final locationNameMap = _readLocations(rawDataRows);

  final list = rawDataRows
      .map((row) {
        final int sequenceNumber =
            switch (row[_FixtureExcelColumns.sequence]?.value) {
          IntCellValue v => v.value,
          TextCellValue v => int.tryParse(v.value.trim()) ?? 0,
          _ => 0,
        };

        if (sequenceNumber == 0) {
          // Ignore the Row.
          return null;
        }

        final int fixtureId = switch (row[_FixtureExcelColumns.fid]?.value) {
          IntCellValue v => v.value,
          TextCellValue v => int.parse(v.value),
          _ => 0,
        };

        final String fixtureTypeName =
            switch (row[_FixtureExcelColumns.fixtureType]?.value) {
          TextCellValue v => v.value.trim(),
          _ => '',
        };

        final String locationId = locationNameMap[_convertRawLocationToString(
                    row[_FixtureExcelColumns.location])]
                ?.uid ??
            '';

        final fixtureType =
            fixtureTypes[fixtureTypeName] ?? const FixtureTypeModel.unknown();

        return FixtureModel(
          uid: getUid(),
          sequence: sequenceNumber,
          fid: fixtureId,
          type: fixtureType,
          locationId: locationId,
        );
      })
      .nonNulls
      .toList();

  return (
    // Fixtures,
    Map<String, FixtureModel>.fromEntries(
        list.map((fixture) => MapEntry(fixture.uid, fixture))),
    // Locations
    Map<String, LocationModel>.fromEntries(locationNameMap.values
        .map((location) => MapEntry(location.uid, location)))
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
    TextCellValue v => v.value.trim(),
    IntCellValue v => v.value.toString().trim(),
    DoubleCellValue v => v.value.toString().trim(),
    _ => '',
  };
}
