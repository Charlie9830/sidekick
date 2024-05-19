import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/balancer/asserts/asserts.dart';
import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/utils/electrical_equations.dart';
import 'package:sidekick/utils/get_multi_patch_from_index.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/utils/round_up_to_nearest_multi_break.dart';

const int _maxAttempts = 3;

class NaiveBalancer implements Balancer {
  /// Takes a list of [FixtureModel], performs Piggybacking then assigns to Outlets.
  /// Does not attempt any Phase Balancing.
  @override
  Map<PowerMultiOutletModel, List<PowerOutletModel>> assignToOutlets({
    required List<FixtureModel> fixtures,
    required List<PowerMultiOutletModel> multiOutlets,
    double maxAmpsPerCircuit = 16,
    int maxSequenceBreak = 4,
  }) {
    // Generate Patches.
    final patchesByLocationId = _generatePatches(
      fixtures: fixtures,
      maxAmpsPerCircuit: maxAmpsPerCircuit,
      maxSequenceBreak: maxSequenceBreak,
    );

    final resultMap = <PowerMultiOutletModel, List<PowerOutletModel>>{};

    for (var entry in patchesByLocationId.entries) {
      final locationId = entry.key;
      final patchesQueue = Queue<PowerPatchModel>.from(entry.value);

      // TODO: We are only assigning the first 6 Channels of each Location. Thats because somewhere below we need to have another loop,
      // It needs to be based off the amount of patches we have left, as in we need to keep looping and popping patches off the queue until
      // we have nothing left.

      final existingMultiOutletsAssignedToLocationQueue =
          Queue<PowerMultiOutletModel>.from(
              multiOutlets.where((multi) => multi.locationId == locationId));

      while (patchesQueue.isNotEmpty) {
        final multiOutlet = existingMultiOutletsAssignedToLocationQueue.isEmpty
            ? PowerMultiOutletModel(
                uid: getUid(),
                locationId: locationId,
                name: 'Not named yet',
                desiredSpareCircuits: 0,
              )
            : existingMultiOutletsAssignedToLocationQueue.removeFirst();

        final patchSlice =
            patchesQueue.pop(6 - multiOutlet.desiredSpareCircuits).toList();

        if (patchSlice.length < 6) {
          final diff = 6 - patchSlice.length;
          patchSlice.addAll([
            for (int i = 1; i <= diff; i++) PowerPatchModel.empty(),
          ]);
        }

        if (multiOutlet.desiredSpareCircuits == 0 &&
            patchSlice.every((patch) => patch.isEmpty)) {
          // No spare circuits required here AND every element in the patch slice is empty. So
          // no point in generating a completing empty Multi Outlet.
          continue;
        }

        final outlets = patchSlice.mapIndexed((index, patch) =>
            PowerOutletModel(
                child: patch,
                locationId: locationId,
                multiOutletId: multiOutlet.uid,
                phase: getPhaseFromIndex(index),
                multiPatch: getMultiPatchFromIndex(index)));

        resultMap[multiOutlet] = outlets.toList();
      }
    }

    return resultMap;
  }

  @override
  BalancerResult balanceOutlets(
    List<PowerOutletModel> outlets, {
    double balanceTolerance = 0.5,
    PhaseLoad initialLoad = const PhaseLoad.zero(),
  }) {
    assert(checkOutletQty(outlets.length),
        'Qty of Outlets is not a multiple of 6. Qty: ${outlets.length}');
    assert(checkPhaseOrdering(outlets),
        'Phase ordering in given outlets is incorrect. ${outlets.mapIndexed((index, outlet) => print('$index: Phase => ${outlet.phase}'))}');

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

      // Before we return this slice. Ensure that we have a good Sequence Number ordering.
      // We do this in 2 passes. Maybe the second pass [_assertInterPhaseNumericOrdering] is redundant.
      return _assertInterPhaseNumericOrdering(
        _assertCrossPhaseNumericOrdering(balancedSlice),
      );
    }).toList();

    return BalancerResult(rawSlices.flattened.toList(), currentLoad);
  }

  Map<String, List<PowerPatchModel>> _generatePatches({
    required List<FixtureModel> fixtures,
    required double maxAmpsPerCircuit,
    required int maxSequenceBreak,
  }) {
    // To Ensure we only Piggyback fixtures local to their own Position. We first group the fixtures by their
    // locations. Then iterate though those locations, calling [performPiggybacking] on each Location.
    final fixturesByLocationId =
        fixtures.groupListsBy((fixture) => fixture.locationId);

    final patchesByLocationId =
        fixturesByLocationId.map((locationId, fixtures) {
      return MapEntry(
          locationId, performPiggybacking(fixtures, maxSequenceBreak));
    });

    // Ensure that for each Location, we have a qty of patches that is a multiple of 6.
    // TODO: Maybe this would be better left to the PowerOutlet assigning part.
    final gapFilledPatchesByLocationId = _fillPatchQty(patchesByLocationId);

    return gapFilledPatchesByLocationId;
  }

  Map<String, List<PowerPatchModel>> _fillPatchQty(
      Map<String, List<PowerPatchModel>> patchesByLocationId) {
    return patchesByLocationId.map((locationId, patches) {
      final desiredNumberOfPatches = roundUpToNearestMultiBreak(patches.length);

      if (patches.length == desiredNumberOfPatches) {
        return MapEntry(locationId, patches);
      }

      if (patches.length > desiredNumberOfPatches) {
        throw "Something has gone wrong. patches.length is greater than desiredNumberOfPatches.";
      }

      final difference = desiredNumberOfPatches - patches.length;
      final gapFillers = List<PowerPatchModel>.generate(
          difference, (index) => PowerPatchModel.empty());

      return MapEntry(locationId, patches.toList()..addAll(gapFillers));
    });
  }

  double _calculateNewRunningPhaseTotal(
      List<PowerOutletModel> slice, int phaseIndex, double currentRunningLoad) {
    return slice
        .where((outlet) => outlet.phase == phaseIndex)
        .map((outlet) => outlet.child.amps)
        .fold(currentRunningLoad, (value, current) => value + current);
  }

  /// Recursively calls itself to attempt to balance the Slice.
  List<PowerOutletModel> _balanceSlice(
    List<PowerOutletModel> slice, {
    int attemptCount = 1,
    required double imbalanceTolerance,
    required PhaseLoad previousLoadsTotal,
  }) {
    // Calculate the current phase Loading by adding the previous loads totals to this slice's load.
    final currentLoad = previousLoadsTotal + _calculatePhaseLoading(slice);

    if (currentLoad.ratio <= imbalanceTolerance) {
      // Slice (and running total of all slices before it) is balanced within desired imbalance tolerance ratio. So no
      // balancing is required for this Slice.
      return slice.toList();
    }

    // Insantiate a new List to which we will make changes on.
    final workingList = slice.toList();

    // Calculate the Lightest and Heaviest phases.
    var (lightestPhase, heaviestPhase) = _calculateLightestAndHeavistLoads(
        currentLoad.asIndexedLoads.$1,
        currentLoad.asIndexedLoads.$2,
        currentLoad.asIndexedLoads.$3);

    // Swap Outlets between the Lightest and heaviest phases to acheive an equilibrium between them.
    _shellShuffleOutletChildren(lightestPhase, heaviestPhase, workingList);

    // Recalculate the new phase loading, and determine if we need to try again.
    final adjustedLoad =
        previousLoadsTotal + _calculatePhaseLoading(workingList);

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
      );
    }

    return workingList;
  }

  (IndexedLoad lightestPhase, IndexedLoad heaviestLoad)
      _calculateLightestAndHeavistLoads(
          IndexedLoad red, IndexedLoad white, IndexedLoad blue) {
    final phases =
        [red, white, blue].sorted((a, b) => (a.load - b.load).round());

    return (phases.first, phases.last);
  }

  (PowerOutletModel a, PowerOutletModel b) _selectOutletsByPhaseIndex(
      int index, List<PowerOutletModel> list) {
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

  (double a, double b) _calculateSwappedLoad(double totalLoadA,
      double totalLoadB, PowerOutletModel a, PowerOutletModel b) {
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
  void _shellShuffleOutletChildren(
      IndexedLoad a, IndexedLoad b, List<PowerOutletModel> list) {
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
    _swapOutletChildren(indexA, indexB, list);
  }

  ///
  /// Swaps the children of the outlets given by [indexA] and [indexB]. Actions are performed to [list] in place.
  ///
  void _swapOutletChildren(
      int indexA, int indexB, List<PowerOutletModel> list) {
    final outletA = list[indexA].copyWith();
    final outletB = list[indexB].copyWith();

    // Swap the children over, Make sure to swap the Spare status flag as well.
    list[indexA] =
        outletA.copyWith(child: outletB.child, isSpare: outletB.isSpare);
    list[indexB] =
        outletB.copyWith(child: outletA.child, isSpare: outletA.isSpare);
  }

  PhaseLoad _calculatePhaseLoading(List<PowerOutletModel> slice) {
    final List<double> loads = [0, 0, 0];

    for (var (index, outlet) in slice.indexed) {
      final lookupIndex = index % 3;

      loads[lookupIndex] = outlet.isSpare
          ? loads[lookupIndex]
          : outlet.child.amps + loads[lookupIndex];
    }

    return PhaseLoad(loads[0], loads[1], loads[2]);
  }

  List<PowerOutletModel> _assertCrossPhaseNumericOrdering(
      List<PowerOutletModel> slice) {
    // Clone the Input List.
    final sliceCopy = slice.toList();

    // Group the outlets by amperage. Outlets that have the same amperage cant be swapped with eachother
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
    final Map<int, PowerOutletModel> resultBuffer = {};

    // Iterate through each group of Outlets with common amperages.
    for (var entry in outletsByAmperage.entries.toList()) {
      final outlets = entry.value;

      // Store the original indexes of the Outlets we will be resorting, so that we can
      // reference them later when writing into the result buffer.
      final originIndexes =
          outlets.map((outlet) => sliceCopy.indexOf(outlet)).toList();

      // Sort the outlets by the Sequence Numebr, then store them as a Queue (Using a queue saves us having to
      // instantiate another variable for tracking the index).
      final sortedBySequenceNumber = Queue<PowerOutletModel>.from(outlets
          .sorted((a, b) => a.child.compareBySequence(b.child))
          .toList());

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
  List<PowerOutletModel> _assertInterPhaseNumericOrdering(
      List<PowerOutletModel> slice) {
    final sliceCopy = slice.toList();
    final phase1Outlets =
        sliceCopy.where((outlet) => outlet.phase == 1).toList();
    final phase2Outlets =
        sliceCopy.where((outlet) => outlet.phase == 2).toList();
    final phase3Outlets =
        sliceCopy.where((outlet) => outlet.phase == 3).toList();

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
      List<PowerOutletModel> phaseOutlets, List<PowerOutletModel> slice) {
    if (phaseOutlets.isEmpty || phaseOutlets.length <= 2) {
      if (phaseOutlets.length > 2) {
        throw "phaseOutlets length was greater than 2. Which is odd. ${phaseOutlets.length}";
      }

      return;
    }

    final firstOutlet = phaseOutlets.first;
    final secondOutlet = phaseOutlets.last;
    if (phaseOutlets.every((outlet) =>
        outlet.child.amps == firstOutlet.child.amps &&
            outlet.isSpare == false ||
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
}
