import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';

///
/// Given a list of [FixtureModel]'s, will return a List of [BalancerPowerPatchModel] with the fixtures
/// piggybacked together, where possible, given the constraints of [maxSequenceBreak] and [FixtureModel.maxAllowedPiggybacks].
///
List<BalancerPowerPatchModel> performPiggybacking(
    List<BalancerFixtureModel> fixtures, int maxSequenceBreak) {
  final Set<String> assignedFixtureUids = {};
  final List<BalancerPowerPatchModel> patches = [];
  int fixtureIndex = 0;
  String currentContigiousRunningFixtureTypeId = '';

  while (patches.length <= assignedFixtureUids.length &&
      fixtureIndex < fixtures.length) {
    final currentFixture = fixtures[fixtureIndex];

    if (assignedFixtureUids.contains(currentFixture.uid)) {
      // Fixture has already been assigned to a patch.
      fixtureIndex++;
      continue;
    }

    // Create a Patch element with the current fixture added to it.
    BalancerPowerPatchModel patch = BalancerPowerPatchModel(fixtures: [
      currentFixture,
    ]);

    currentContigiousRunningFixtureTypeId = currentFixture.type.uid;

    if (currentFixture.type.canPiggyback == false) {
      // Current Fixture can't Piggyback with anything else. So we are done here.
      patches.add(patch);

      currentContigiousRunningFixtureTypeId = '';
      assignedFixtureUids.add(currentFixture.uid);

      fixtureIndex++;
      continue;
    }

    // Attempt to search ahead in the list of fixtures for suitable fixtures to Piggyback with.
    // Look ahead up to a max of the maxSequenceBreak.. So we don't end up pairing fixtures that
    // are miles from eachother.
    for (int sequenceOffset = 1;
        sequenceOffset <= maxSequenceBreak ||
            _canOverrideMaxSequenceBreak(currentFixture, maxSequenceBreak,
                currentContigiousRunningFixtureTypeId);
        sequenceOffset++) {
      final candidateFixture =
          fixtures.elementAtOrNull(fixtureIndex + sequenceOffset);

      if (candidateFixture == null) {
        break;
      }

      if (candidateFixture.type == currentFixture.type &&
          patch.fixtures.length + 1 <= currentFixture.type.maxPiggybacks) {
        patch.fixtures.add(candidateFixture);

        if (candidateFixture.type.uid !=
            currentContigiousRunningFixtureTypeId) {
          currentContigiousRunningFixtureTypeId = '';
        }
      }
    }

    // Add the Patch to the buffer list, add the fixture UIDs to the assignedIds set and iterate.
    patches.add(patch);
    assignedFixtureUids.addAll(patch.fixtures.map((fixture) => fixture.uid));
    fixtureIndex++;
  }

  return patches;
}

/// The properties of Some fixture types can allow for the rules to be bent when it comes to Max Sequence break.
/// This function will return true if the [currentFixture] meets those conditions.
bool _canOverrideMaxSequenceBreak(BalancerFixtureModel currentFixture,
    int maxSequenceBreak, String currentContigiousRunningFixtureTypeId) {
  // If the Fixture Type allows for more Piggybacks then the Max Sequence break, and we are running a contigious line of that fixture type
  // return true
  return (currentFixture.type.maxPiggybacks > maxSequenceBreak &&
      currentFixture.type.uid == currentContigiousRunningFixtureTypeId);
}
