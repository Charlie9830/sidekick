import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sidekick/balancer/asserts/asserts.dart';
import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_intermediate_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_multi_outlet_model.dart';
import 'package:sidekick/balancer/models/patch_contents.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/balancer/power_span.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/balancer/models/balancer_outlet_model.dart';
import 'package:sidekick/utils/electrical_equations.dart';
import 'package:sidekick/utils/get_multi_patch_from_index.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/utils/round_up_to_nearest_multi_break.dart';

typedef CleanupFunction = List<BalancerOutletModel> Function(
    List<BalancerOutletModel> slice);

const int _maxAttempts = 3;

class NaiveBalancer implements Balancer {
  /// Takes a list of [FixtureModel], performs Piggybacking then assigns to Outlets.
  /// Does not attempt any Phase Balancing.
  @override
  List<BalancerMultiOutletModel> assignToOutlets({
    required List<BalancerFixtureModel> fixtures,
    required List<PowerMultiOutletModel> multiOutlets,
    required Map<String, BalancerLocationModel> locations,
    required Map<String, FixtureTypePoolModel> allFixtureTypePools,
    double maxAmpsPerCircuit = 16,
    int globalMaxSequenceBreak = 4,
  }) {
    // Generate Patches.
    final patchesByLocationId = _generatePatches(
      fixtures: fixtures,
      allFixtureTypePools: allFixtureTypePools,
      maxAmpsPerCircuit: maxAmpsPerCircuit,
      globalMaxSequenceBreak: globalMaxSequenceBreak,
      locations: locations,
    );

    final List<BalancerMultiOutletModel> updatedMultis = [];

    for (final locationEntry in patchesByLocationId.entries) {
      final locationId = locationEntry.key;
      final patchesInLocation = locationEntry.value;

      final existingMultiOutletsAssignedToLocationQueue =
          Queue<PowerMultiOutletModel>.from(
              multiOutlets.where((multi) => multi.locationId == locationId));

      final patchesQueue = Queue<PatchContents>.from(patchesInLocation);

      while (patchesQueue.isNotEmpty) {
        // Create a new Multi Outlet if we don't have one, otherwise use an existing one.
        final multiOutlet = existingMultiOutletsAssignedToLocationQueue.isEmpty
            ? BalancerMultiOutletModel(
                uid: getUid(),
                locationId: locationId,
                number:
                    0, // We will iterate through and update these once we have the full picture.
                name: '',
                children: [],
                parentRack: const PowerMultiRackAssignment.unassigned(),
                desiredSpareCircuits: 0,
              )
            : BalancerMultiOutletModel.fromMultiOutletWithoutChildren(
                existingMultiOutletsAssignedToLocationQueue.removeFirst());

        final patchSlice =
            patchesQueue.pop(6 - multiOutlet.desiredSpareCircuits).toList();

        if (patchSlice.length < 6) {
          final diff = 6 - patchSlice.length;
          patchSlice.addAll([
            for (int i = 1; i <= diff; i++) PatchContents.empty(),
          ]);
        }

        if (multiOutlet.desiredSpareCircuits == 0 &&
            patchSlice.every((patch) => patch.isEmpty)) {
          // No spare circuits required here AND every element in the patch slice is empty. So
          // no point in generating a completly empty Multi Outlet.
          continue;
        }

        final outlets = patchSlice.mapIndexed(
          (index, patch) => BalancerOutletModel(
            contents: patch,
            locationId: locationId,
            multiOutletId: multiOutlet.uid,
            phase: getPhaseFromIndex(index),
            multiPatch: getMultiPatchFromIndex(index),
            fixtureTypePoolId: patch.fixtureTypePoolId,
          ),
        );

        updatedMultis.add(multiOutlet.copyWith(
          children: outlets.toList(),
        ));
      }
    }

    final multisByLocationId =
        updatedMultis.groupListsBy((multi) => multi.locationId);

    final withAssertedMultiNumbering = multisByLocationId.entries
        .map((entry) {
          final multisInLocation = entry.value;

          return multisInLocation.mapIndexed((index, multi) {
            return multi.copyWith(
              number: index + 1,
            );
          });
        })
        .flattened
        .toList();

    return withAssertedMultiNumbering;
  }

  @override
  BalancerResult balanceOutlets(
    List<BalancerOutletModel> outlets, {
    double balanceTolerance = 0.5,
    PhaseLoad initialLoad = const PhaseLoad.zero(),
  }) {
    assert(checkOutletQty(outlets.length),
        'Qty of Outlets is not a multiple of 6. Qty: ${outlets.length}');
    assert(checkPhaseOrdering(outlets),
        'Phase ordering in given outlets is incorrect. ${outlets.mapIndexed((index, outlet) => debugPrint('$index: Phase => ${outlet.phase}'))}');

    // Slice the list of Outlets up into 6 (Socapex Amount). Then "massage" each slice to get as close to
    // balanced as we can.
    final outletSlices = outlets.slices(6);

    // Instantiate a variable to keep track of Phase loading as we balance each slice.
    var currentLoad = PhaseLoad(initialLoad.a, initialLoad.b, initialLoad.c);

    final rawSlices = outletSlices.mapIndexed((index, slice) {
      if (slice.length != 6) {
        return slice;
      }

      final balancedSlice = _balanceSlice(
        slice,
        imbalanceTolerance: balanceTolerance,
        previousLoadsTotal: currentLoad,
      );

      // Update the running Phase Totals.
      currentLoad += _calculatePhaseLoading(balancedSlice);

      return balancedSlice;
    }).toList();

    return BalancerResult(rawSlices.flattened.toList(), currentLoad);
  }

  // Generates a Map of Patches indexed by their Location Id.
  // Used to index by Power Span. but that is contained to just Piggybacking now.
  Map<String, List<PatchContents>> _generatePatches({
    required List<BalancerFixtureModel> fixtures,
    required Map<String, FixtureTypePoolModel> allFixtureTypePools,
    required double maxAmpsPerCircuit,
    required int globalMaxSequenceBreak,
    required Map<String, BalancerLocationModel> locations,
  }) {
    final powerSpans = PowerSpan.createSpans(fixtures);

    final patchesBySpan = Map<PowerSpan, List<PatchContents>>.fromEntries(
        powerSpans.map((span) => MapEntry(
            span,
            performPiggybacking(
              fixtures: span.fixtures
                  .map((fixture) => IntermediateFixtureModel(
                        type: fixture.type,
                        locationId: fixture.locationId,
                        sequence: fixture.sequence,
                        ephemeralId: getUid(),
                      ))
                  .toList(),
              allFixtureTypePools: allFixtureTypePools,
              globalMaxSequenceBreak: globalMaxSequenceBreak,
              locations: locations,
            ))));

    final patchesByLocation = Map<String, List<PatchContents>>.from(
        patchesBySpan.entries.fold<Map<String, List<PatchContents>>>({},
            (accum, item) {
      final currentSpan = item.key;
      final patchesInSpan = item.value;

      if (accum.containsKey(currentSpan.locationId) == false) {
        accum[currentSpan.locationId] = [];
      }

      accum[currentSpan.locationId]!.addAll(patchesInSpan);

      return accum;
    }))
      ..updateAll((_, patches) => _fillPatchQty(patches));

    return patchesByLocation;
  }

  List<PatchContents> _fillPatchQty(List<PatchContents> patches) {
    final desiredNumberOfPatches = roundUpToNearestMultiBreak(patches.length);

    if (patches.length == desiredNumberOfPatches) {
      return patches;
    }

    if (patches.length > desiredNumberOfPatches) {
      throw "Something has gone wrong. patches.length is greater than desiredNumberOfPatches.";
    }

    final difference = desiredNumberOfPatches - patches.length;
    final gapFillers = List<PatchContents>.generate(
        difference, (index) => PatchContents.empty());

    return patches.toList()..addAll(gapFillers);
  }
}

/// Recursively calls itself to attempt to balance the Slice.
List<BalancerOutletModel> _balanceSlice(
  List<BalancerOutletModel> slice, {
  int attemptCount = 1,
  required double imbalanceTolerance,
  required PhaseLoad previousLoadsTotal,
  List<BalancerResult> previousResults = const [],
}) {
  if (imbalanceTolerance >= 1) {
    return slice.toList();
  }

  // Perform a deep Clone of the Slice. This is because later on we capture
  final clonedSlice = slice
      .map((outlet) => outlet.copyWith(
            contents: outlet.contents.copyWith(),
          ))
      .toList();

  // Calculate the current phase Loading by adding the previous loads totals to this slice's load.
  final currentLoad = previousLoadsTotal + _calculatePhaseLoading(clonedSlice);

  if (currentLoad.ratio <= imbalanceTolerance) {
    // Slice (and running total of all slices before it) is balanced within desired imbalance tolerance ratio. So no
    // balancing is required for this Slice.
    return clonedSlice.toList();
  }

  // Insantiate a new List to which we will make changes on.
  List<BalancerOutletModel> workingList = clonedSlice.toList();

  // Calculate the Lightest and Heaviest phases.
  var (lightestPhase, heaviestPhase) = _calculateLightestAndHeavistLoads(
      currentLoad.asIndexedLoads.$1,
      currentLoad.asIndexedLoads.$2,
      currentLoad.asIndexedLoads.$3);

  // Swap Outlets between the Lightest and heaviest phases to acheive an equilibrium between them.
  workingList =
      _shellShuffleOutletChildren(lightestPhase, heaviestPhase, workingList);

  // Recalculate the new phase loading, and determine if we need to try again.
  final adjustedLoad = previousLoadsTotal + _calculatePhaseLoading(workingList);

  if (adjustedLoad.ratio <= imbalanceTolerance) {
    // We have acheived an adequate Balance..
    return workingList;
  }

  // If we got here, we are still not balanced enough. So we will try again recursively until
  // we are within the tolerance, or run out of attempts.
  if (attemptCount == 1) {
    // Recurse into Second Attempt.
    attemptCount = 2;
    return _balanceSlice(
      workingList,
      attemptCount: attemptCount,
      imbalanceTolerance: imbalanceTolerance,
      previousLoadsTotal: previousLoadsTotal,
      previousResults: [BalancerResult(workingList, adjustedLoad)],
    );
  }

  // Subsequent Attempts
  if (attemptCount <= _maxAttempts) {
    // Less than 3 attempts. Take another Bite.
    attemptCount += 1;
    return _balanceSlice(
      workingList,
      attemptCount: attemptCount,
      imbalanceTolerance: imbalanceTolerance,
      previousLoadsTotal: previousLoadsTotal,
      previousResults: [
        ...previousResults,
        BalancerResult(workingList, adjustedLoad)
      ],
    );
  }

  // Well we ran out of Attempts. We should just return the best attempt we had.
  if (previousResults.isEmpty) {
    if (kDebugMode) {
      print(
          "Something has gone wrong. Previous Results shouldn't be empty here");
    }
  }

  return _selectBestBalancingResult(
      [...previousResults, BalancerResult(workingList, adjustedLoad)]).outlets;
}

BalancerResult _selectBestBalancingResult(List<BalancerResult> results) {
  final sortedResults =
      results.sorted((a, b) => (a.load.neutral - b.load.neutral).round());

  return sortedResults.first;
}

(IndexedLoad lightestPhase, IndexedLoad heaviestLoad)
    _calculateLightestAndHeavistLoads(
        IndexedLoad red, IndexedLoad white, IndexedLoad blue) {
  final phases = [red, white, blue].sorted((a, b) => (a.load - b.load).round());

  return (phases.first, phases.last);
}

(BalancerOutletModel a, BalancerOutletModel b) _selectOutletsByPhaseIndex(
    int index, List<BalancerOutletModel> list) {
  if (list.length != 6) {
    throw "Cannot select outlets from a list smaller then 6 elements. Ensure each Patch Slice is asserted to be 6 elements";
  }

  const int offset = 3;
  return switch (index) {
    0 => (list[0], list[0 + offset]),
    1 => (list[1], list[1 + offset]),
    2 => (list[2], list[2 + offset]),
    _ => throw ArgumentError(
        '[index] argument must be between 0 and 2 (Zero based Phase Index). Argument provided is $index'),
  };
}

(double a, double b) _calculateSwappedLoad(double totalLoadA, double totalLoadB,
    BalancerOutletModel a, BalancerOutletModel b) {
  return (
    totalLoadA - a.contents.amps + b.contents.amps,
    totalLoadB - b.contents.amps + a.contents.amps,
  );
}

/// Return the index of the best (Lowest) balance score.
int _findBestScoreIndex(List<double> scores) {
  final lowestScore = scores.min;

  final index = scores.indexOf(lowestScore);

  if (index == -1) {
    throw "Something went wrong whilst trying to find the best score index. Result of scores.indexOf was -1";
  }

  return index;
}

// Lower is better.
double _calculateLoadBalanceScore(
    double loadA, double loadB, double targetLoad) {
  return ((loadA - targetLoad).abs() + (loadB - targetLoad).abs());
}

/// Selects children of the given [list] of outlets and swaps them based on how close the
/// swap will get the phases to the median load between them (Midpoint load between [a] and [b]).
List<BalancerOutletModel> _shellShuffleOutletChildren(
    IndexedLoad a, IndexedLoad b, List<BalancerOutletModel> list) {
  // The target Load is the median load between the two phases. ie: The midpoint betweeen the phases.
  final targetLoad = median([a.load, b.load]);

  // Select Outlets based on their Phase Index. In an abcabc phasing system, this will be 2 outlets
  // per phase.
  final (a1, a2) = _selectOutletsByPhaseIndex(a.index, list);
  final (b1, b2) = _selectOutletsByPhaseIndex(b.index, list);

  // Build a "Truth Table" like structure of all the possible variations of outlet swaps.
  final swapVariations = [
    [a1, b1],
    [a1, b2],
    [a2, b1], // Probably a redundant pair.
    [a2, b2]
  ];

  // For each swap pair. Calculate the result of swapping those outlets on the total load of each phase.
  final swappedLoads = swapVariations
      .map((pair) => _calculateSwappedLoad(a.load, b.load, pair[0], pair[1]))
      .toList();

  // For each of the variations of Swaps. Calculate a score (lower is better) of how close the new phase loadings
  // are to the target Load (Median load).
  final loadSwapScores = swappedLoads
      .map((loadPair) =>
          _calculateLoadBalanceScore(loadPair.$1, loadPair.$2, targetLoad))
      .toList();

  // Find the index of the best score.
  final bestSwapIndex = _findBestScoreIndex(loadSwapScores);

  // Instantiate the indexes of our two Swap tributes by referencing the best swap index, back through the [swapVariations] and then
  // extracting the list indexes of those from the provided outlet list.
  final indexA = list.indexOf(swapVariations[bestSwapIndex].first);
  final indexB = list.indexOf(swapVariations[bestSwapIndex].last);

  if (indexA == -1 || indexB == -1) {
    throw "Something wen't wrong whilst Swapping Outlet Children. list.indexOf returned -1 to either indexA or indexB";
  }

  // Swap Outlet children.
  return _swapOutletChildren(indexA, indexB, list);
}

///
/// Swaps the children of the outlets given by [indexA] and [indexB].
///
List<BalancerOutletModel> _swapOutletChildren(
    int indexA, int indexB, List<BalancerOutletModel> list) {
  final clone = list.toList();

  final outletA = clone[indexA].copyWith();
  final outletB = clone[indexB].copyWith();

  // Swap the children over, Make sure to swap the Spare status and the fixtureTypePoolId flag as well.
  clone[indexA] = outletA.copyWith(
      contents: outletB.contents,
      isSpare: outletB.isSpare,
      fixtureTypePoolId: outletB.fixtureTypePoolId);
  clone[indexB] = outletB.copyWith(
      contents: outletA.contents,
      isSpare: outletA.isSpare,
      fixtureTypePoolId: outletA.fixtureTypePoolId);

  return clone;
}

PhaseLoad _calculatePhaseLoading(List<BalancerOutletModel> slice) {
  final List<double> loads = [0, 0, 0];

  for (var (index, outlet) in slice.indexed) {
    final lookupIndex = index % 3;

    loads[lookupIndex] = outlet.isSpare
        ? loads[lookupIndex]
        : outlet.contents.amps + loads[lookupIndex];
  }

  return PhaseLoad(loads[0], loads[1], loads[2]);
}
