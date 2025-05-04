import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/utils/get_uid.dart';

Future<ImportRawFixturesResult> readRawFixtures(
    {required PatchImportSettings settings,
    required String patchFilePath}) async {
  return switch (settings.source) {
    // TODO: Handle this case.
    PatchSource.grandMA2XML => throw UnimplementedError(),
    // TODO: Handle this case.
    PatchSource.mvr =>
      await _readMvrPatch(patchFilePath: patchFilePath, settings: settings)
  };
}

Future<ImportRawFixturesResult> _readMvrPatch(
    {required String patchFilePath,
    required PatchImportSettings settings}) async {
  final mvrReader = MVR(filePath: patchFilePath);
  final readResult = await mvrReader.read(expandGdtfFiles: false);

  if (readResult == false) {
    return ImportRawFixturesResult(
        fixtures: [],
        error: 'An unknown error occurred reading the MVR file.',
        locations: []);
  }

  final rawFixtures = mvrReader.generalSceneDescription.layers
      .map(
        (layer) => layer.fixtures.map(
          (fixture) => RawFixtureModel(
            generatedId: getUid(),
            mvrId: fixture.uuid,
            mvrLayerId: layer.uuid,
            fixtureId: int.tryParse(fixture.fixtureId) ?? 0,
            fixtureIdString: fixture.fixtureId,
            fixtureMode: fixture.gdtfMode,
            fixtureType: fixture.gdtfSpec,
            address: DMXAddressModel.fromGlobal(
                fixture.addresses.singleGlobalAddress ?? 0),
            mvrLocationId: switch (settings.mvrLocationDataSource) {
              MvrLocationDataSource.layers => layer.uuid,
              // TODO: Handle this case.
              MvrLocationDataSource.classes => throw UnimplementedError(),
              // TODO: Handle this case.
              MvrLocationDataSource.position => throw UnimplementedError(),
            },
            locationName: switch (settings.mvrLocationDataSource) {
              MvrLocationDataSource.layers => layer.name,
              MvrLocationDataSource.classes => fixture.classing,
              MvrLocationDataSource.position => fixture.position,
            },
          ),
        ),
      )
      .flattened;

  final locations = Map<String, RawLocationModel>.fromEntries(
      rawFixtures.map((fixture) => MapEntry(
          fixture.mvrLocationId,
          RawLocationModel(
            mvrId: fixture.mvrLocationId,
            generatedId: '',
            name: fixture.locationName,
          ))));

  return ImportRawFixturesResult(
      fixtures: rawFixtures.toList(),
      error: null,
      locations: locations.values.toList());
}

class ImportRawFixturesResult {
  final List<RawFixtureModel> fixtures;
  final List<RawLocationModel> locations;
  final String? error;

  ImportRawFixturesResult({
    required this.fixtures,
    required this.error,
    required this.locations,
  });
}
