import 'dart:io';

import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/utils/get_uid.dart';

Future<Map<String, FixtureTypeModel>> readFixtureTypeTestData(
    String path) async {
  final file = File(path);

  if (await file.exists() == false) {
    throw "Fixture Type Test Data file cannot be found at\n${file.path}";
  }

  final excel = Excel.decodeBytes(await file.readAsBytes());

  if (excel.tables.containsKey('Fixture Types') == false) {
    throw "'Fixture Types' sheet cannot be found in Fixture Types Test data, at \n${file.path}";
  }

  final sheet = excel.tables['Fixture Types']!;

  final rows = sheet.rows.sublist(1); // Ignore Headers

  final interim = rows
      .map((row) {
        final String name = switch (row[0]?.value) {
          TextCellValue v => v.value.trim(),
          _ => '',
        };

        final double amps = switch (row[1]?.value) {
          TextCellValue v => double.parse(v.value.trim()),
          IntCellValue v => v.value.toDouble(),
          DoubleCellValue v => v.value,
          _ => 0,
        };

        final int maxPiggybacks = switch (row[2]?.value) {
          TextCellValue v => int.parse(v.value.trim()),
          IntCellValue v => v.value,
          _ => 1,
        };

        if (name.isEmpty) {
          return null;
        }

        final uid = getUid();

        return FixtureTypeModel(
          uid: uid,
          name: name,
          shortName: name,
          amps: amps,
          maxPiggybacks: maxPiggybacks,
        );
      })
      .nonNulls
      .toList()
    ..add(FixtureTypeModel(
      uid: '',
    ));

  return Map<String, FixtureTypeModel>.fromEntries(
      interim.map((item) => MapEntry(item.name, item)));
}
