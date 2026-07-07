import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/balancer/models/balancer_intermediate_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_outlet_model.dart';
import 'package:sidekick/balancer/models/patch_contents.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/utils/get_multi_patch_from_index.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';

void main() {
  group('NaiveBalancer.balanceOutlets', () {
    test('preserves outlet ordering when no swap improves the balance', () {
      // Regression test: 5 fixtures piggybacked in 2s produce patches
      // (1,2), (3,4), (5). The phase loading (10A, 10A, 5A) exceeds the
      // balance tolerance but no outlet swap can improve it, so the
      // balancer must leave the ordering untouched rather than performing
      // a pointless swap that scrambles the fixture sequence.
      final type = FixtureTypeModel(
        uid: 'type-a',
        name: 'Wash',
        shortName: 'Wash',
        amps: 5,
        maxPiggybacks: 2,
      );

      final outlets = _buildOutlets([
        _patch(type, sequences: [1, 2]),
        _patch(type, sequences: [3, 4]),
        _patch(type, sequences: [5]),
        PatchContents.empty(),
        PatchContents.empty(),
        PatchContents.empty(),
      ]);

      final result = NaiveBalancer().balanceOutlets(
        outlets,
        balanceTolerance: 0.5,
      );

      expect(_sequencesOf(result.outlets[0]), [1, 2]);
      expect(_sequencesOf(result.outlets[1]), [3, 4]);
      expect(_sequencesOf(result.outlets[2]), [5]);
      expect(result.outlets[3].contents.isEmpty, true);
      expect(result.outlets[4].contents.isEmpty, true);
      expect(result.outlets[5].contents.isEmpty, true);
    });

    test('still swaps outlets when a swap strictly improves the balance', () {
      // Phase loads are (10A, 4A, 8A). Swapping the 6A patch on phase 1
      // with a 2A patch on phase 2 yields (6A, 8A, 8A), which is within
      // tolerance. The guard against no-benefit swaps must not block
      // genuinely useful ones.
      final outlets = _buildOutlets([
        _patch(_typeOfAmps(6), sequences: [1]),
        _patch(_typeOfAmps(2), sequences: [2]),
        _patch(_typeOfAmps(4), sequences: [3]),
        _patch(_typeOfAmps(4), sequences: [4]),
        _patch(_typeOfAmps(2), sequences: [5]),
        _patch(_typeOfAmps(4), sequences: [6]),
      ]);

      final result = NaiveBalancer().balanceOutlets(
        outlets,
        balanceTolerance: 0.5,
      );

      expect(result.outlets[0].contents.amps, 2);
      expect(result.outlets[1].contents.amps, 6);
      expect(result.load.ratio, lessThanOrEqualTo(0.5));
    });
  });
}

/// Builds a 6-way slice of outlets with correct abcabc phase ordering.
List<BalancerOutletModel> _buildOutlets(List<PatchContents> patches) {
  assert(patches.length == 6);

  return [
    for (final (index, patch) in patches.indexed)
      BalancerOutletModel(
        contents: patch,
        locationId: 'location-1',
        multiOutletId: 'multi-1',
        phase: getPhaseFromIndex(index),
        multiPatch: getMultiPatchFromIndex(index),
        fixtureTypePoolId: '',
      ),
  ];
}

PatchContents _patch(FixtureTypeModel type, {required List<int> sequences}) {
  return PatchContents(
    fixtureTypePoolId: '',
    fixtures: [
      for (final sequence in sequences)
        IntermediateFixtureModel(
          type: type,
          locationId: 'location-1',
          sequence: sequence,
          ephemeralId: 'fixture-$sequence',
        ),
    ],
  );
}

FixtureTypeModel _typeOfAmps(double amps) {
  return FixtureTypeModel(uid: 'type-$amps', amps: amps);
}

List<int> _sequencesOf(BalancerOutletModel outlet) {
  return outlet.contents.fixtures.map((fixture) => fixture.sequence).toList();
}
