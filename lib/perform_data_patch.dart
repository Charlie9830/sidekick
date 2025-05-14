import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/assert_data_multi_and_patch_state.dart';
import 'package:sidekick/classes/universe_span.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/utils/get_uid.dart';

Map<String, DataPatchModel> performDataPatch({
  required Map<String, FixtureModel> fixtures,
  required bool honorDataSpans,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, LocationModel> locations,
}) {
  final fixturesByLocationId =
      fixtures.values.groupListsBy((fixture) => fixture.locationId);

  final spansByLocationId = fixturesByLocationId.map(
    (locationId, fixtures) => MapEntry(
      locationId,
      honorDataSpans
          ? UniverseSpan.createSpans(fixtures)
          : fixtures
              .groupListsBy((fix) => fix.dmxAddress.universe)
              .entries
              .map((entry) => UniverseSpan(
                    fixtureIds:
                        entry.value.map((fixture) => fixture.uid).toList(),
                    startsAt: entry.value.first,
                    universe: entry.key,
                    endsAt: entry.value.last,
                  )),
    ),
  );

  final List<DataPatchModel> patches = [];

  for (final entry in spansByLocationId.entries) {
    final locationId = entry.key;
    final spans = entry.value;

    final patchesInLocation =
        dataPatches.values.where((patch) => patch.locationId == locationId);

    final Queue<DataPatchModel> existingPatches =
        Queue<DataPatchModel>.from(patchesInLocation);

    final location = locations[locationId]!;

    for (final (index, span) in spans.indexed) {
      final basePatch = existingPatches.isNotEmpty
          ? existingPatches.removeFirst()
          : DataPatchModel(
              uid: getUid(),
              locationId: locationId,
            );

      patches.add(basePatch.copyWith(
        name: location.getPrefixedDataPatch(index + 1),
        number: index + 1,
        universe: span.universe,
        startsAtFixtureId: span.startsAt.fid,
        endsAtFixtureId: span.endsAt?.fid ?? 0,
        fixtureIds: span.fixtureIds,
        isSpare: false,
      ));
    }
  }

  final assertedPatches = assertDataPatchState(patches.toModelMap(), locations);

  return assertedPatches;
}
