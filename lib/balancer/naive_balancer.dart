import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/utils/electrical_equations.dart';

class NaiveBalancer implements BalancerBase {
  @override
  List<PowerPatchModel> generatePatches(
      {required List<FixtureModel> fixtures,
      required double maxAmpsPerCircuit}) {
    return performPiggybacking(fixtures, 3);
  }

  @override
  List<PowerOutletModel> assignToOutlets(
      List<PowerPatchModel> patches, List<PowerOutletModel> outlets) {
    return _assignToOutlets(outlets: outlets, patches: patches);
  }

  List<PowerOutletModel> _assignToOutlets({
    required List<PowerOutletModel> outlets,
    required List<PowerPatchModel> patches,
  }) {
    final outletSlices = outlets.slices(6);
    final patchesQueue = Queue.from(patches);

    final rawSlices = outletSlices.map((slice) {
      final populatedOutlets = slice.map((outlet) {
        if (outlet.isSpare || patchesQueue.isEmpty) {
          return outlet;
        }

        return outlet.copyWith(child: patchesQueue.removeFirst());
      });

      return _balanceSlice(populatedOutlets.toList());
    });

    return rawSlices.expand((slice) => slice).toList();
  }

  /// Recursively calls itself to attempt to balance the Slice.
  List<PowerOutletModel> _balanceSlice(List<PowerOutletModel> slice,
      {int? attempts}) {
    final [red, white, blue] = _calculatePhaseLoading(slice);

    final phaseBalanceRatio =
        calculateBalanceRatio(red.load, white.load, blue.load);

    if (phaseBalanceRatio == 0) {
      return slice.toList();
    }

    final workingList = slice.toList();

    final phases =
        [red, white, blue].sorted((a, b) => (a.load - b.load).round());

    final lightestPhase = phases.first;
    final heaviestPhase = phases.last;

    _swapOutletChildren(lightestPhase.index, heaviestPhase.index, workingList);

    // Begin Recursion.
    if (attempts == null) {
      // First Attempt.
      attempts = 1;
      return _balanceSlice(workingList, attempts: attempts);
    }

    // Subsequent Attempts
    if (attempts <= 3) {
      // Less than 3 attempts. Take another Bite.
      attempts += 1;
      return _balanceSlice(workingList, attempts: attempts);
    } else {
      return workingList;
    }
  }

  void _swapOutletChildren(int indexA, indexB, List<PowerOutletModel> list) {
    if (indexA >= list.length || indexB >= list.length) {
      return;
    }

    final redCandidate = list[indexA].copyWith();
    final blueCandidate = list[indexB].copyWith();

    list[indexA] = redCandidate.copyWith(child: blueCandidate.child);
    list[indexB] = blueCandidate.copyWith(child: redCandidate.child);
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

  (_Phase red, _Phase white, _Phase blue) _balancePhases(
      List<PowerPatchModel> patches) {
    final red = _Phase();
    final white = _Phase();
    final blue = _Phase();

    for (final patch in patches) {
      _selectLightestPhase(red, white, blue).patches.add(patch);
    }

    return (red, white, blue);
  }

  _Phase _selectLightestPhase(_Phase a, _Phase b, _Phase c) {
    if (a.load <= b.load && a.load <= c.load) {
      return a;
    }

    if (b.load <= a.load && b.load <= c.load) {
      return b;
    }

    if (c.load <= a.load && c.load <= b.load) {
      return c;
    }

    return a;
  }
}

class _Phase {
  final Queue<PowerPatchModel> patches = Queue();

  _Phase();
  double get load => patches
      .map((patch) => patch.amps)
      .fold(0, (value, element) => value + element);
}

class IndexedLoad {
  final int index;
  final double load;

  IndexedLoad(this.index, this.load);
}
