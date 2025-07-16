import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';

///
/// Given a list of [FixtureModel]'s, will return a List of [BalancerPowerPatchModel] with the fixtures
/// piggybacked together, where possible, given the constraints of [globalMaxSequenceBreak] and [FixtureModel.maxAllowedPiggybacks].
///
List<BalancerPowerPatchModel> performPiggybacking({
  required List<BalancerFixtureModel> fixtures,
  required int globalMaxSequenceBreak,
  required Map<String, BalancerLocationModel> locations,
}) {
  final Set<String> assignedFixtureUids = {};
  final List<BalancerPowerPatchModel> patches = [];
  int fixtureIndex = 0;

  while (patches.length <= assignedFixtureUids.length &&
      fixtureIndex < fixtures.length) {
    BalancerFixtureModel currentFixture = fixtures[fixtureIndex];

    if (assignedFixtureUids.contains(currentFixture.uid)) {
      // Fixture has already been assigned to a patch.
      fixtureIndex++;
      continue;
    }

    // Create a Patch element with the current fixture added to it.
    BalancerPowerPatchModel patch = BalancerPowerPatchModel(fixtures: [
      currentFixture,
    ]);

    // Collect and apply any location specific patch settings we have to the fixture type.
    final currentLocationOverride =
        locations[currentFixture.locationId]?.overrides;
    currentFixture = currentFixture.copyWith(
        type: currentFixture.type.copyWith(
            maxPiggybacks:
                currentLocationOverride?.maxPairings[currentFixture.type.uid]));

    // Determine if we are adhearing to the Global max Sequence break, or a Location specific one.
    final currentMaxSequenceBreak =
        currentLocationOverride?.maxSequenceBreak.value ??
            globalMaxSequenceBreak;

    if (currentFixture.type.canPiggyback == false) {
      // Current Fixture can't Piggyback with anything else. So we are done here.
      patches.add(patch);

      assignedFixtureUids.add(currentFixture.uid);

      fixtureIndex++;
      continue;
    }

    int sequenceOffset = 0;
    while (true) {
      sequenceOffset++;

      final candidateFixture =
          fixtures.elementAtOrNull(fixtureIndex + sequenceOffset);

      if (candidateFixture == null) {
        // No more candidate fixtures.
        break;
      }

      final fixtureTypesMatch =
          candidateFixture.type.uid == currentFixture.type.uid;
      final satisfiesMaxPiggybacks =
          patch.fixtures.length + 1 <= currentFixture.type.maxPiggybacks;
      final allowedToOverrideMaxSequenceBreak =
          patch.isContiguousWith(candidateFixture) == true;
      final satisfiesMaxSequenceBreak =
          sequenceOffset <= currentMaxSequenceBreak;

      // Check if we violate the "Critical" Conditions first, these are the unbreakable decrees.
      // 1. We can never Pair fixtures of differing types.
      // 2. We can never pair fixtures beyond their maxPiggyback count.
      if (fixtureTypesMatch == false) {
        continue;
      }

      if (satisfiesMaxPiggybacks == false) {
        break;
      }

      // Now check if we violate any of the more lenient rules, then act accordingly.
      if (satisfiesMaxSequenceBreak) {
        patch.fixtures.add(candidateFixture);
        continue;
      }

      if (allowedToOverrideMaxSequenceBreak) {
        patch.fixtures.add(candidateFixture);
        continue;
      }
    }

    // Add the Patch to the buffer list, add the fixture UIDs to the assignedIds set and iterate.
    patches.add(patch);
    assignedFixtureUids.addAll(patch.fixtures.map((fixture) => fixture.uid));
    fixtureIndex++;
  }

  return patches;
}
