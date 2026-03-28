import 'package:collection/collection.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';

List<BalancerPowerPatchModel> performPiggybacking({
  required List<BalancerFixtureModel> fixtures,
  required int globalMaxSequenceBreak,
  required Map<String, BalancerLocationModel> locations,
  required Map<String, FixtureTypePoolModel> allFixtureTypePools,
}) {
  final assigned = <String>{};
  final patches = <BalancerPowerPatchModel>[];

  for (int i = 0; i < fixtures.length; i++) {
    final base = fixtures[i];

    // Check if we haven't already assigned this Fixture to an earlier Patch.
    if (assigned.contains(base.uid)) continue;

    // Fetch Location specific overrides (if any)
    final locationOverride = locations[base.locationId]?.overrides;

    // Optionally apply location specific overrides.
    final baseFixture = base.copyWith(
      type: base.type.copyWith(
        maxPiggybacks: locationOverride?.maxPairings[base.type.uid],
      ),
    );

    // Optionally apply Location specific Max Sequence break.
    final maxSequenceBreak =
        locationOverride?.maxSequenceBreak.value ?? globalMaxSequenceBreak;

    // Collect any Fixture Type Pools that are enabled for this location.
    final availableFixtureTypePools = locationOverride
            ?.enabledFixtureTypePoolIds
            .map((id) => allFixtureTypePools[id])
            .nonNulls
            .toList() ??
        [];

    // Maintain a list of Fixtures that are candidates for getting grouped into this patch.
    // Add the the base fixture to that list.
    final candidateFixtures = <BalancerFixtureModel>[baseFixture];
    assigned.add(baseFixture.uid);

    // Collect the first Fixture Type Pool (if any) that is compatiable with the base fixture.
    final pool = availableFixtureTypePools.firstWhereOrNull(
      (p) => p.containsFixtureType(baseFixture.type.uid),
    );

    // Look ahead For loop.
    for (int j = i + 1; j < fixtures.length; j++) {
      final candidate = fixtures[j];

      // Check if the candidate fixture has not already been assigned to an earlier patch.
      if (assigned.contains(candidate.uid)) continue;

      final sequenceOffset = j - i;

      // Collect some comparisons between the base and candidate fixtures.
      final sameType = candidate.type.uid == baseFixture.type.uid;
      final poolMatch = pool?.containsFixtureType(candidate.type.uid) ?? false;

      final withinSequence = sequenceOffset <= maxSequenceBreak ||
          _isContiguous([candidateFixtures.last, candidate]);

      // Check that we haven't strayed beyond the MaxSequenceBreak.
      if (!withinSequence) break;

      // We have a Pool match, atleast in theory.
      if (poolMatch) {
        // Check that we aren't breaking the Max Pool Item quantity.
        final valid = pool!.satisfiesMaxPoolQuantity([
          ...candidateFixtures.map((f) => f.type.uid),
          candidate.type.uid,
        ]);
        if (!valid) break;

        // All good to collect into a Pool.
        candidateFixtures.add(candidate);
        assigned.add(candidate.uid);
        continue;
      }

      // No matching pool available and fixtures aren't of same type. So break.
      if (!sameType) break;

      if (candidateFixtures.length + 1 > baseFixture.type.maxPiggybacks) {
        // Adding the candidate fixture would violate max piggybacks.
        break;
      }

      candidateFixtures.add(candidate);
      assigned.add(candidate.uid);
    }

    patches.add(BalancerPowerPatchModel(fixtures: candidateFixtures));
  }

  return patches;
}

bool _isContiguous(List<BalancerFixtureModel> fixtures) {
  if (fixtures.isEmpty || fixtures.length == 1) {
    return false;
  }

  final contiguousFixtures = fixtures.whereIndexed((index, current) {
    if (index == 0) {
      return true;
    }

    final BalancerFixtureModel? previous = fixtures.elementAtOrNull(index - 1);

    if (previous == null) {
      return true;
    }

    if (previous.type.uid != current.type.uid) {
      return false;
    }

    return previous.sequence == current.sequence - 1;
  });

  return contiguousFixtures.length == fixtures.length;
}
