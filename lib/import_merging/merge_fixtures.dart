import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';

Map<String, FixtureModel> mergeFixtures(
    {required Map<String, FixtureModel> existing,
    required Map<String, FixtureModel> incoming,
    required ImportSettingsModel settings}) {
  final incomingFixturesByFid = Map<int, FixtureModel>.fromEntries(
      incoming.entries.map((entry) => MapEntry(entry.value.fid, entry.value)));

  final existingFixturesByFid = Map<int, FixtureModel>.fromEntries(
      existing.entries.map((entry) => MapEntry(entry.value.fid, entry.value)));

  final updatedFixtures = existingFixturesByFid.entries.map((entry) {
    final fid = entry.key;

    if (incomingFixturesByFid.containsKey(fid)) {
      return _cherryPickFixtureUpdates(
          entry.value, incomingFixturesByFid[fid]!, settings);
    }

    return entry.value;
  }).toList();

  if (settings.type == ImportType.addNewRecords) {
    updatedFixtures.addAll(incomingFixturesByFid.values.where(
        (fixture) => incomingFixturesByFid.containsKey(fixture.fid) == false));
  }

  return convertToModelMap(updatedFixtures);
}

FixtureModel _cherryPickFixtureUpdates(FixtureModel existing,
    FixtureModel incoming, ImportSettingsModel settings) {
  return existing.copyWith(
    type: settings.overwriteType ? incoming.type : existing.type,
    dmxAddress:
        settings.overwriteAddress ? incoming.dmxAddress : existing.dmxAddress,
    locationId:
        settings.overwriteLocation ? incoming.locationId : existing.locationId,
    sequence:
        settings.overwriteSeqNumber ? incoming.sequence : existing.sequence,
  );
}
