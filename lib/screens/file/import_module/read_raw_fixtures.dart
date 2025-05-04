import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:xml/xml.dart';

Future<ImportRawFixturesResult> readRawFixtures(
    {required PatchImportSettings settings,
    required String patchFilePath}) async {
  return switch (settings.source) {
    PatchSource.grandMA2XML =>
      await _readMa2XmlPatch(patchFilePath: patchFilePath, settings: settings),
    PatchSource.mvr =>
      await _readMvrPatch(patchFilePath: patchFilePath, settings: settings)
  };
}

Future<ImportRawFixturesResult> _readMa2XmlPatch(
    {required String patchFilePath,
    required PatchImportSettings settings}) async {
  final sourceFile = File(patchFilePath);

  if (await sourceFile.exists() == false) {
    return ImportRawFixturesResult(
        fixtures: [],
        error: 'The provided XML file does not exist.',
        locations: []);
  }

  final fileContents = await sourceFile.readAsString();

  if (fileContents.isEmpty) {
    return ImportRawFixturesResult(
        fixtures: [], error: 'The provided XML file is empty.', locations: []);
  }

  final XmlDocument document;
  try {
    document = XmlDocument.parse(fileContents);
  } catch (e) {
    return ImportRawFixturesResult(
        fixtures: [], error: 'Invalid XML File. $e', locations: []);
  }

  final root = document.rootElement;
  final layers =
      root.childElements.where((element) => element.localName == "Layer");

  // Pull Locations first so we can assign these to fixtures.
  final locations = layers
      .map((element) => element.getAttribute('name'))
      .nonNulls
      .map((name) =>
          RawLocationModel(mvrId: '', generatedId: getUid(), name: name))
      .toList();

  final locationsByName = Map<String, RawLocationModel>.fromEntries(
      locations.map((location) => MapEntry(location.name, location)));

  final fixtures = layers
      .map((layerElement) {
        final layerName = layerElement.getAttribute("name") ?? '';

        return layerElement.childElements
            .where((element) => element.localName == "Fixture")
            .map((fixtureElement) {
          final rawFixtureNameData = _extractMa2FixtureNameData(fixtureElement);
          final dmxAddress = _extractMa2DmxAddress(fixtureElement);

          final fixtureId = fixtureElement.getAttribute("fixture_id") ?? '';

          return RawFixtureModel(
            generatedId: getUid(),
            locationName: layerName,
            address: dmxAddress,
            fixtureId: int.tryParse(fixtureId) ?? 0,
            fixtureIdString: fixtureId,
            fixtureType: rawFixtureNameData,
            fixtureMode: rawFixtureNameData,
            generatedLocationId: locationsByName[layerName]?.generatedId ?? '',
            mvrId: '',
            mvrLayerId: '',
            mvrLocationId: '',
          );
        });
      })
      .flattened
      .toList();

  return ImportRawFixturesResult(
      fixtures: fixtures, error: null, locations: locations);
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

DMXAddressModel _extractMa2DmxAddress(XmlElement fixtureElement) {
  final addressElement = fixtureElement
      .findElements("SubFixture")
      .first
      .findElements("Patch")
      .first
      .findElements("Address")
      .first;

  final rawAddress = addressElement.innerText;

  return DMXAddressModel.fromGlobal(int.tryParse(rawAddress) ?? 0);
}

String _extractMa2FixtureNameData(XmlElement fixtureElement) {
  final fixtureTypeElement = fixtureElement.childElements
      .firstWhere((element) => element.localName == "FixtureType");

  return fixtureTypeElement.getAttribute('name') ?? 'COULD NOT FIND';
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
