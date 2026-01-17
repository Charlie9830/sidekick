import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sidekick/balancer/asserts/asserts.dart';
import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_multi_outlet_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/balancer/power_span.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
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
    double maxAmpsPerCircuit = 16,
    int globalMaxSequenceBreak = 4,
  }) {
    // Generate Patches.
    final patchesByLocationId = _generatePatches(
      fixtures: fixtures,
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

      final patchesQueue =
          Queue<BalancerPowerPatchModel>.from(patchesInLocation);

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
                desiredSpareCircuits: 0,
              )
            : BalancerMultiOutletModel.fromMultiOutletWithoutChildren(
                existingMultiOutletsAssignedToLocationQueue.removeFirst());

        final patchSlice =
            patchesQueue.pop(6 - multiOutlet.desiredSpareCircuits).toList();

        if (patchSlice.length < 6) {
          final diff = 6 - patchSlice.length;
          patchSlice.addAll([
            for (int i = 1; i <= diff; i++) BalancerPowerPatchModel.empty(),
          ]);
        }

        if (multiOutlet.desiredSpareCircuits == 0 &&
            patchSlice.every((patch) => patch.isEmpty)) {
          // No spare circuits required here AND every element in the patch slice is empty. So
          // no point in generating a completly empty Multi Outlet.
          continue;
        }

        final outlets = patchSlice.mapIndexed((index, patch) =>
            BalancerOutletModel(
                child: patch,
                locationId: locationId,
                multiOutletId: multiOutlet.uid,
                phase: getPhaseFromIndex(index),
                multiPatch: getMultiPatchFromIndex(index)));

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

      // Before we return this slice. Run some cleanup functions on it in order.
      // We first declare these functions in a list, then run them sequentially daisy chaining their results with the .fold function.

      final cleanupFunctions = <CleanupFunction>[
        _assertCrossPhaseNumericOrdering,
        _assertInterPhaseNumericOrdering,
        _assertUnevenPiggybackOrdering,
      ];

      return cleanupFunctions.fold(
          balancedSlice, (value, cleanupFunc) => cleanupFunc(value));
    }).toList();

    return BalancerResult(rawSlices.flattened.toList(), currentLoad);
  }

  // Generates a Map of Patches indexed by their Location Id.
  // Used to index by Power Span. but that is contained to just Piggybacking now.
  Map<String, List<BalancerPowerPatchModel>> _generatePatches({
    required List<BalancerFixtureModel> fixtures,
    required double maxAmpsPerCircuit,
    required int globalMaxSequenceBreak,
    required Map<String, BalancerLocationModel> locations,
  }) {
    final powerSpans = PowerSpan.createSpans(fixtures);

    final patchesBySpan =
        Map<PowerSpan, List<BalancerPowerPatchModel>>.fromEntries(
            powerSpans.map((span) => MapEntry(
                span,
                performPiggybacking(
                  fixtures: span.fixtures,
                  globalMaxSequenceBreak: globalMaxSequenceBreak,
                  locations: locations,
                ))));

    final patchesByLocation = Map<String, List<BalancerPowerPatchModel>>.from(
        patchesBySpan.entries.fold<Map<String, List<BalancerPowerPatchModel>>>(
            {}, (accum, item) {
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

  List<BalancerPowerPatchModel> _fillPatchQty(
      List<BalancerPowerPatchModel> patches) {
    final desiredNumberOfPatches = roundUpToNearestMultiBreak(patches.length);

    if (patches.length == desiredNumberOfPatches) {
      return patches;
    }

    if (patches.length > desiredNumberOfPatches) {
      throw "Something has gone wrong. patches.length is greater than desiredNumberOfPatches.";
    }

    final difference = desiredNumberOfPatches - patches.length;
    final gapFillers = List<BalancerPowerPatchModel>.generate(
        difference, (index) => BalancerPowerPatchModel.empty());

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
  // Perform a deep Clone of the Slice. This is because later on we capture
  final clonedSlice = slice
      .map((outlet) => outlet.copyWith(
            child: outlet.child.copyWith(),
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
    totalLoadA - a.child.amps + b.child.amps,
    totalLoadB - b.child.amps + a.child.amps,
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

  // Swap the children over, Make sure to swap the Spare status flag as well.
  clone[indexA] =
      outletA.copyWith(child: outletB.child, isSpare: outletB.isSpare);
  clone[indexB] =
      outletB.copyWith(child: outletA.child, isSpare: outletA.isSpare);

  return clone;
}

PhaseLoad _calculatePhaseLoading(List<BalancerOutletModel> slice) {
  final List<double> loads = [0, 0, 0];

  for (var (index, outlet) in slice.indexed) {
    final lookupIndex = index % 3;

    loads[lookupIndex] = outlet.isSpare
        ? loads[lookupIndex]
        : outlet.child.amps + loads[lookupIndex];
  }

  return PhaseLoad(loads[0], loads[1], loads[2]);
}

List<BalancerOutletModel> _assertUnevenPiggybackOrdering(
    List<BalancerOutletModel> slice) {
  // We can end up in a situation where we have Uneven Piggybacking, this is generally triggered by a slice having a given qty of piggybackable fixtures
  // which then aren't evenly divisible by that Fixtures maxPiggyback ammount.
  // EG:
  /*
    // Circuit      Type        Fixture ID's
      --------------------------------------
      1            Strike x3   102, 103, 104
      2            Strike x1   101
      -------------------------------------
    In reality, fixture 101 should be appearing first, we can't just swap it as it would upset the balance,
    therefore we need to Bit shift 101 into circuit one and Bit shift 104 off onto circuit 2.
    */

  // Query to determine if we could possibly have this issue present in this slice.
  final outletsWithPiggybacks = slice.where((outlet) =>
      outlet.isSpare == false &&
      outlet.child.isNotEmpty &&
      outlet.child.fixtures.first.type.canPiggyback);

  // Then Group those by fixture Type.
  final byFixtureType = outletsWithPiggybacks
      .groupListsBy((outlet) => outlet.child.fixtures.first.type.uid);

  // Then determine if we have any with uneven piggybacking (ie one circuit has a different qty of fixtures then another)
  final withUnevenPiggybacking = byFixtureType.entries.where((entry) {
    final outlets = entry.value;

    return outlets.any((outlet) =>
        outlet.child.fixtures.length != outlets.first.child.fixtures.length);
  });

  if (withUnevenPiggybacking.isEmpty) {
    // No issues present. Business as usual.
    return slice.toList();
  }

  // Init a copy of the original slice for us to make changes to.
  final workingSlice = slice.toList();

  // Iterate through each Fixture group that has uneven piggybacking and make the approriate changes to the workingSlice.
  for (final entry in withUnevenPiggybacking) {
    final outlets = entry.value;

    // Capture the original indexes of the outlets, we will use these to re insert into the slice later.
    final sourceIndexes =
        outlets.map((outlet) => slice.indexOf(outlet)).toList();

    // Capture how many fixtures were assigned to each outlet.
    final outletFixtureQtys =
        outlets.map((outlet) => outlet.child.fixtures.length).toList();

    // Extract the Fixtures and sort them by sequence number.
    final sortedFixtures = outlets
        .map((outlet) => outlet.child.fixtures)
        .flattened
        .sorted((a, b) => a.sequence - b.sequence);

    // Convert the fixtures into a Queue.
    final fixturesQueue = Queue<BalancerFixtureModel>.from(sortedFixtures);

    // Re insert the fixtures into the Outlet in a more suitable order, obeying the respective quantities.
    int i = 0;
    for (final sourceIndex in sourceIndexes) {
      final existingOutlet = workingSlice[sourceIndex].copyWith();

      workingSlice[sourceIndex] = existingOutlet.copyWith(
          child: existingOutlet.child.copyWith(
        fixtures: fixturesQueue.pop(outletFixtureQtys[i]).toList(),
      ));

      i++;
    }
  }

  return workingSlice;
}

List<BalancerOutletModel> _assertCrossPhaseNumericOrdering(
    List<BalancerOutletModel> slice) {
  // Clone the Input List.
  final sliceCopy = slice.toList();

  // Group the outlets by amperage. Outlets that have the same amperage can be swapped with eachother
  // without affect overall phase balance.
  final outletsByAmperage =
      sliceCopy.groupListsBy((outlet) => outlet.child.amps);

  if (outletsByAmperage.keys.length == 6) {
    // All unique Amperages, So cannot continue.
    return slice;
  }

  // Instantiate a buffer to store the results. This is because
  // we will be adding indexes out of order, which we can't use List.Add or list.insert when
  // they are out of numeric order.
  final Map<int, BalancerOutletModel> resultBuffer = {};

  // Iterate through each group of Outlets with common amperages.
  for (var entry in outletsByAmperage.entries.toList()) {
    final outlets = entry.value;

    // Store the original indexes of the Outlets we will be resorting, so that we can
    // reference them later when writing into the result buffer.
    final originIndexes =
        outlets.map((outlet) => sliceCopy.indexOf(outlet)).toList();

    // Sort the outlets by the Sequence Numeber, then store them as a Queue (Using a queue saves us having to
    // instantiate another variable for tracking the index).
    final sortedBySequenceNumber = Queue<BalancerOutletModel>.from(
        outlets.sorted((a, b) => a.child.compareBySequence(b.child)).toList());

    // Iterate through the origin indexes.
    for (var originalIndex in originIndexes) {
      final sourceOutlet = sortedBySequenceNumber.removeFirst();

      // At the Original Index, swap in the new Child and isSpare flag.
      // We are pulling the SourceOutlet from the sortedByFID queue, which is... well sorted by FID.
      resultBuffer[originalIndex] = sliceCopy[originalIndex].copyWith(
        child: sourceOutlet.child,
        isSpare: sourceOutlet.isSpare,
      );
    }
  }

  // Ensure the keys (indexes) are in numeric order.
  final sortedKeys = resultBuffer.keys.toList()..sort();

  // Return a simple List.
  return sortedKeys.map((key) => resultBuffer[key]!).toList();
}

///
/// Asserts a numeric ordering of Fixture numbers where possible. Constrained only to outlets that belong on the
/// same Phase.
///
List<BalancerOutletModel> _assertInterPhaseNumericOrdering(
    List<BalancerOutletModel> slice) {
  final sliceCopy = slice.toList();
  final phase1Outlets = sliceCopy.where((outlet) => outlet.phase == 1).toList();
  final phase2Outlets = sliceCopy.where((outlet) => outlet.phase == 2).toList();
  final phase3Outlets = sliceCopy.where((outlet) => outlet.phase == 3).toList();

  // Maybe swap children so that Fixture numbers are numerically correct.
  // Performs modifications in place to [sliceCopy]
  _maybeNumericallyShuffleSortOutlets(phase1Outlets, sliceCopy);
  _maybeNumericallyShuffleSortOutlets(phase2Outlets, sliceCopy);
  _maybeNumericallyShuffleSortOutlets(phase3Outlets, sliceCopy);

  return sliceCopy;
}

///
/// Will swap the place of the given [phaseOutlets] in [slice] as long as
/// Outlets have the same amperage.
/// Outlets are not spare.
/// Outlets are not Empty.
/// The latter outlet has a numerically smaller fixture number then the former outlet.
/// Modifications are performed in Place to [slice]
void _maybeNumericallyShuffleSortOutlets(
    List<BalancerOutletModel> phaseOutlets, List<BalancerOutletModel> slice) {
  if (phaseOutlets.isEmpty || phaseOutlets.length <= 2) {
    if (phaseOutlets.length > 2) {
      throw "phaseOutlets length was greater than 2. Which is odd. ${phaseOutlets.length}";
    }

    return;
  }

  final firstOutlet = phaseOutlets.first;
  final secondOutlet = phaseOutlets.last;
  if (phaseOutlets.every((outlet) =>
      outlet.child.amps == firstOutlet.child.amps && outlet.isSpare == false ||
      outlet.child.isEmpty == false)) {
    final int seqA = firstOutlet.child.fixtures.isNotEmpty
        ? firstOutlet.child.fixtures.first.sequence
        : 0;
    final int seqB = secondOutlet.child.fixtures.isNotEmpty
        ? secondOutlet.child.fixtures.first.sequence
        : 0;

    if (seqA > seqB) {
      // Swap Outlets.
      _swapOutletChildren(
          slice.indexOf(firstOutlet), slice.indexOf(secondOutlet), slice);
    }
  }
}
