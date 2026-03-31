import 'package:collection/collection.dart';
import 'package:sidekick/balancer/models/balancer_intermediate_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';

List<BalancerPowerPatchModel> performPiggybacking({
  required List<IntermediateFixtureModel> fixtures,
  required int globalMaxSequenceBreak,
  required Map<String, BalancerLocationModel> locations,
  required Map<String, FixtureTypePoolModel> allFixtureTypePools,
}) {
  final assigned = <String>{};
  final patches = <BalancerPowerPatchModel>[];

  for (int i = 0; i < fixtures.length; i++) {
    final base = fixtures[i];

    // Check if we haven't already assigned this Fixture to an earlier Patch.
    if (assigned.contains(base.ephemeralId)) continue;

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

    // Attempt a strict pool match.
    List<IntermediateFixtureModel>? poolMatchedFixtures;
    final pool = availableFixtureTypePools.firstWhereOrNull((p) {
      poolMatchedFixtures = _tryMatchPoolStrictly(
        startIndex: i,
        fixtures: fixtures,
        assigned: assigned,
        pool: p,
        maxSequenceBreak: maxSequenceBreak,
      );
      return poolMatchedFixtures != null;
    });

    if (pool != null && poolMatchedFixtures != null) {
      assigned.addAll({
        baseFixture.ephemeralId,
        ...poolMatchedFixtures!.map((fix) => fix.ephemeralId)
      });

      patches.add(BalancerPowerPatchModel(
          fixtures: poolMatchedFixtures!, fixtureTypePoolId: pool.uid));
      continue;
    }

    // Fallback to normal piggybacking.
    final candidateFixtures = <IntermediateFixtureModel>[baseFixture];
    assigned.add(baseFixture.ephemeralId);

    // Look ahead For loop.
    for (int j = i + 1; j < fixtures.length; j++) {
      final candidate = fixtures[j];

      // Check if the candidate fixture has not already been assigned to an earlier patch.
      if (assigned.contains(candidate.ephemeralId)) continue;

      final sequenceOffset = j - i;

      // Collect some comparisons between the base and candidate fixtures.
      final sameType = candidate.type.uid == baseFixture.type.uid;

      final withinSequence = sequenceOffset <= maxSequenceBreak ||
          _isContiguous([candidateFixtures.last, candidate]);

      // Check that we haven't strayed beyond the MaxSequenceBreak.
      if (!withinSequence) break;

      // Base and Candidate Fixtures aren't of the same Type.
      if (!sameType) continue;

      if (candidateFixtures.length + 1 > baseFixture.type.maxPiggybacks) {
        // Adding the candidate fixture would violate max piggybacks.
        break;
      }

      candidateFixtures.add(candidate);
      assigned.add(candidate.ephemeralId);
    }

    patches.add(BalancerPowerPatchModel(
        fixtures: candidateFixtures, fixtureTypePoolId: ''));
  }

  return patches;
}

bool _isContiguous(List<IntermediateFixtureModel> fixtures) {
  if (fixtures.isEmpty || fixtures.length == 1) {
    return false;
  }

  final contiguousFixtures = fixtures.whereIndexed((index, current) {
    if (index == 0) {
      return true;
    }

    final IntermediateFixtureModel? previous =
        fixtures.elementAtOrNull(index - 1);

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

List<IntermediateFixtureModel>? _tryMatchPoolStrictly({
  required int startIndex,
  required List<IntermediateFixtureModel> fixtures,
  required Set<String> assigned,
  required FixtureTypePoolModel pool,
  required int maxSequenceBreak,
}) {
  final List<IntermediateFixtureModel> matched = [];
  final Map<String, int> currentCounts = {};

  for (int j = startIndex; j < fixtures.length; j++) {
    final candidate = fixtures[j];

    if (pool.containsFixtureType(candidate.type.uid) == false) break;

    if (assigned.contains(candidate.ephemeralId)) continue;

    final sequenceOffset = j - startIndex;

    if (j > startIndex) {
      final withinSequence = sequenceOffset <= maxSequenceBreak ||
          _isContiguous([matched.last, candidate]);

      if (!withinSequence) break;
    }

    if (pool.containsFixtureType(candidate.type.uid)) {
      final requiredQty = pool.items[candidate.type.uid]?.qty ?? 0;
      final currentQty = currentCounts[candidate.type.uid] ?? 0;

      if (currentQty < requiredQty) {
        matched.add(candidate);
        currentCounts[candidate.type.uid] = currentQty + 1;
      }
    }

    bool allMet = true;
    for (final item in pool.items.values) {
      if ((currentCounts[item.typeId] ?? 0) != item.qty) {
        allMet = false;
        break;
      }
    }
    if (allMet) return matched;
  }
  return null;
}
