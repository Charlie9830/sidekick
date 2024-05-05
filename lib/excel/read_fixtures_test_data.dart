import 'dart:io';

import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/utils/get_uid.dart';

Future<Map<String, FixtureModel>> readFixturesTestData(
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

  final list = sheet.rows
      .sublist(1)
      .map((row) {
        final int sequenceNumber = switch (row[0]?.value) {
          IntCellValue v => v.value,
          TextCellValue v => int.tryParse(v.value.trim()) ?? 0,
          _ => 0,
        };

        if (sequenceNumber == 0) {
          // Ignore the Row.
          return null;
        }

        final int fixtureId = switch (row[1]?.value) {
          IntCellValue v => v.value,
          TextCellValue v => int.parse(v.value),
          _ => 0,
        };

        final String fixtureTypeName = switch (row[2]?.value) {
          TextCellValue v => v.value.trim(),
          _ => '',
        };

        final String location = switch (row[3]?.value) {
          TextCellValue v => v.value.trim(),
          _ => '',
        };

        final fixtureType =
            fixtureTypes[fixtureTypeName] ?? const FixtureTypeModel.unknown();

        return FixtureModel(
          uid: getUid(),
          sequence: sequenceNumber,
          fid: fixtureId,
          type: fixtureType,
          location: location,
        );
      })
      .nonNulls
      .toList();

  return Map<String, FixtureModel>.fromEntries(
      list.map((fixture) => MapEntry(fixture.uid, fixture)));
}
