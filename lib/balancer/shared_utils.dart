import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/utils/get_uid.dart';

///
/// Given a list of [FixtureModel]'s, will return a List of [PowerPatchModel] with the fixtures
/// piggybacked together, where possible, given the constraints of [maxSequenceBreak] and [FixtureModel.maxAllowedPiggybacks].
///
List<PowerPatchModel> performPiggybacking(
    List<FixtureModel> fixtures, int maxSequenceBreak) {
  final Set<String> assignedFixtureUids = {};
  final List<PowerPatchModel> patches = [];
  int fixtureIndex = 0;

  while (patches.length <= assignedFixtureUids.length &&
      fixtureIndex < fixtures.length) {
    final currentFixture = fixtures[fixtureIndex];
    if (assignedFixtureUids.contains(currentFixture.uid)) {
      // Fixture has already been assigned to a patch.
      fixtureIndex++;
      continue;
    }

    // Create a Patch element with the current fixture added to it.
    PowerPatchModel patch = PowerPatchModel(fixtures: [
      currentFixture,
    ]);

    if (currentFixture.type.canPiggyback == false) {
      // Current Fixture can't Piggyback with anything else. So we are done here.
      patches.add(patch);

      assignedFixtureUids.add(currentFixture.uid);
      fixtureIndex++;
      continue;
    }

    // Attempt to search ahead in the list of fixtures for suitable fixtures to Piggyback with.
    // Look ahead up to a max of the maxSequenceBreak.. So we don't end up pairing fixtures that
    // are miles from eachother.
    for (int sequenceOffset = 1;
        sequenceOffset <= maxSequenceBreak;
        sequenceOffset++) {
      final candidateFixture =
          fixtures.elementAtOrNull(fixtureIndex + sequenceOffset);

      if (candidateFixture == null) {
        break;
      }

      if (candidateFixture.type == currentFixture.type &&
          patch.fixtures.length + 1 <= currentFixture.type.maxPiggybacks) {
        patch.fixtures.add(candidateFixture);
      }
    }

    // Add the Patch to the buffer list, add the fixture UIDs to the assignedIds set and iterate.
    patches.add(patch);
    assignedFixtureUids.addAll(patch.fixtures.map((fixture) => fixture.uid));
    fixtureIndex++;
  }

  return patches;
}
