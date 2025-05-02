import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/utils/get_uid.dart';

(List<RawFixtureModel> fixtures, List<RawLocationModel> locations)
    associateLocations(
        {required PatchImportSettings settings,
        required List<RawFixtureModel> fixtures}) {
  final embeddedLocationsByName = fixtures.fold<Map<String, RawLocationModel>>(
    {},
    (map, fixture) => map.containsKey(fixture.locationName) ? map : map.clone()
      ..addAll(
        {
          fixture.locationName: RawLocationModel(
            generatedId: getUid(),
            mvrId: fixture.mvrLocationId,
            name: fixture.locationName,
          ),
        },
      ),
  );

  final updatedFixtures = fixtures.map((fixture) {
    final rawLocation = embeddedLocationsByName[fixture.locationName]!;

    return fixture.copyWith(
        associatedLocationId: switch (settings.source) {
      PatchSource.grandMA2XML => rawLocation.generatedId,
      PatchSource.mvr => rawLocation.mvrId
    });
  });

  return (updatedFixtures.toList(), embeddedLocationsByName.values.toList());
}
