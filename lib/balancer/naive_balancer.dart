import 'dart:collection';

import 'package:sidekick/balancer/balancer_base.dart';
import 'package:sidekick/balancer/shared_utils.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

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
    final phases = _balancePhases(patches);

    return _assignToOutlets(
        outlets: outlets, red: phases.$1, white: phases.$2, blue: phases.$3);
  }

  List<PowerOutletModel> _assignToOutlets(
      {required List<PowerOutletModel> outlets,
      required _Phase red,
      required _Phase white,
      required _Phase blue}) {
    return outlets.map((outlet) {
      if (outlet.isSpare) {
        return outlet;
      }

      final sourcePhase = switch (outlet.phase) {
        1 => red,
        2 => white,
        3 => blue,
        _ => throw const FormatException('Unknown Phase number'),
      };

      if (sourcePhase.patches.isEmpty) {
        return outlet;
      }

      return outlet.copyWith(child: sourcePhase.patches.removeFirst());
    }).toList();
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
