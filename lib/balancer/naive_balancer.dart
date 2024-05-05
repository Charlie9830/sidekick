import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/utils/electrical_equations.dart';
import 'package:sidekick/utils/round_up_to_nearest_multi_break.dart';

const int _maxAttempts = 3;

class NaiveBalancer implements BalancerBase {
  @override
  List<PowerPatchModel> generatePatches({
    required List<FixtureModel> fixtures,
    required double maxAmpsPerCircuit,
    int maxSequenceBreak = 4,
  }) {
    final fixturesByLocation =
        fixtures.groupListsBy((fixture) => fixture.location);

    final patchesByLocation = fixturesByLocation.map((location, fixtures) {
      return MapEntry(
          location, performPiggybacking(fixtures, maxSequenceBreak));
    });

    final gapFilledPatchesByLocation =
        patchesByLocation.map((location, patches) {
      final desiredNumberOfPatches = roundUpToNearestMultiBreak(patches.length);

      if (patches.length == desiredNumberOfPatches) {
        return MapEntry(location, patches);
      }

      if (patches.length > desiredNumberOfPatches) {
        throw "Something has gone wrong. patches.length is greater than desiredNumberOfPatches.";
      }

      final difference = desiredNumberOfPatches - patches.length;
      final gapFillers = List<PowerPatchModel>.generate(
          difference, (index) => PowerPatchModel.empty());

      return MapEntry(location, patches.toList()..addAll(gapFillers));
    });

    return gapFilledPatchesByLocation.values.expand((i) => i).toList();
  }

  @override
  List<PowerOutletModel> assignToOutlets({
    required List<PowerPatchModel> patches,
    required List<PowerOutletModel> outlets,
    double imbalanceTolerance = 0.1,
  }) {
    // Slice the list of Outlets up into 6 (Socapex Ammount). Then "massage" each slice to get as close to
    // balanced as we can.
    final outletSlices = outlets.slices(6);
    final patchesQueue = Queue.from(patches);

    // Instantiate some variables to track our total load by phase as we iterate through and balance each slice.
    // Each slice gets balanced with respect to the Slices before it.
    double phaseARunningTotal = 0;
    double phaseBRunningTotal = 0;
    double phaseCRunningTotal = 0;

    final rawSlices = outletSlices.mapIndexed((index, slice) {
      // Pre assign Patches to Outlets. But only if the outlet is not a spare and we have
      // patches available.
      final populatedOutlets = slice.map((outlet) {
        if (outlet.isSpare || patchesQueue.isEmpty) {
          return outlet;
        }

        return outlet.copyWith(child: patchesQueue.removeFirst());
      }).toList();

      final balancedSlice = _balanceSlice(
        populatedOutlets.toList(),
        imbalanceTolerance: imbalanceTolerance,
        currentPhaseALoad: phaseARunningTotal,
        currentPhaseBLoad: phaseBRunningTotal,
        currentPhaseCLoad: phaseCRunningTotal,
      );

      // Update the running Phase Totals.
      phaseARunningTotal =
          _calculateNewRunningPhaseTotal(balancedSlice, 1, phaseARunningTotal);
      phaseBRunningTotal =
          _calculateNewRunningPhaseTotal(balancedSlice, 2, phaseBRunningTotal);
      phaseCRunningTotal =
          _calculateNewRunningPhaseTotal(balancedSlice, 3, phaseCRunningTotal);

      // Before we return this slice. Ensure that we have a good FID ordering.
      // We do this in 2 passes. Maybe the second pass [_assertInterPhaseNumericOrdering] is redundant.
      return _assertInterPhaseNumericOrdering(
        _assertCrossPhaseNumericOrdering(balancedSlice),
      );
    }).toList();

    return rawSlices.expand((slice) => slice).toList();
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
    required double currentPhaseALoad,
    required double currentPhaseBLoad,
    required double currentPhaseCLoad,
  }) {
    // Get the Phase loading for this Slice only.
    var [red, white, blue] = _calculatePhaseLoading(slice);

    // Append the Phase loading of previous slices to this one.
    red.load = red.load + currentPhaseALoad;
    white.load = white.load + currentPhaseBLoad;
    blue.load = blue.load + currentPhaseCLoad;

    // Calculate the ratio of phase imbalance of this Slice, inclusive of the total of all slices before this one.
    final phaseImbalanceRatio = calculateImbalanceRatio(
      red.load,
      white.load,
      blue.load,
    );

    if (phaseImbalanceRatio <= imbalanceTolerance) {
      // Slice (and running total of all slices before it) is balanced within desired imbalance tolerance ratio.
      return slice.toList();
    }

    final workingList = slice.toList();

    // Calculate the Lightest and Heaviest phases.
    var (lightestPhase, heaviestPhase) =
        _calculateLightestAndHeavistLoads(red, white, blue);

    // Swap Outlets between the Lightest and heaviest phases to acheive an equilibrium between them.
    _shellShuffleOutletChildren(lightestPhase, heaviestPhase, workingList);

    // Recalculate the new phase loading, and determine if we need to try again.
    [red, white, blue] = _calculatePhaseLoading(workingList);
    red.load += currentPhaseALoad;
    white.load += currentPhaseBLoad;
    blue.load += currentPhaseCLoad;

    final newPhaseImbalanceRatio =
        calculateImbalanceRatio(red.load, white.load, blue.load);

    if (newPhaseImbalanceRatio <= imbalanceTolerance) {
      // We are in balance enough. No need to try again.
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
        currentPhaseALoad: currentPhaseALoad,
        currentPhaseBLoad: currentPhaseBLoad,
        currentPhaseCLoad: currentPhaseCLoad,
      );
    }

    // Subsequent Attempts
    if (attemptCount <= _maxAttempts) {
      // Less than 3 attempts. Take another Bite.
      attemptCount += 1;
      return _balanceSlice(workingList,
          attemptCount: attemptCount,
          imbalanceTolerance: imbalanceTolerance,
          currentPhaseALoad: currentPhaseALoad,
          currentPhaseBLoad: currentPhaseBLoad,
          currentPhaseCLoad: currentPhaseCLoad);
    } else {
      return workingList;
    }
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

  List<IndexedLoad> _calculatePhaseLoading(List<PowerOutletModel> slice) {
    final List<double> loads = [0, 0, 0];

    for (var outlet in slice) {
      final index = outlet.phase - 1;
      loads[index] =
          outlet.isSpare ? loads[index] : outlet.child.amps + loads[index];
    }

    return [
      IndexedLoad(0, loads[0]),
      IndexedLoad(1, loads[1]),
      IndexedLoad(2, loads[2]),
    ];
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

    // Maybe swaps children so that Fixture numbers are numerically correct.
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
      final int fidA = firstOutlet.child.fixtures.isNotEmpty
          ? firstOutlet.child.fixtures.first.fid
          : 0;
      final int fidB = secondOutlet.child.fixtures.isNotEmpty
          ? secondOutlet.child.fixtures.first.fid
          : 0;

      if (fidA > fidB) {
        // Swap Outlets.
        _swapOutletChildren(
            slice.indexOf(firstOutlet), slice.indexOf(secondOutlet), slice);
      }
    }
  }
}

/// Represents a phase loading along with it's ZERO BASED index.
class IndexedLoad {
  final int index;
  double load;

  IndexedLoad(int index, this.load) : index = _assertZeroBasedIndex(index);

  /// Asserts that the provided [index] is Zero based.
  static int _assertZeroBasedIndex(int index) {
    if (index >= 0 && index <= 2) {
      return index;
    }

    throw ArgumentError(
        "The [index] parameter provided to [IndexedLoad] must be Zero based. Value received = $index");
  }
}
