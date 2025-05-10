import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerPatchViewModel {
  final List<PowerPatchRow> rows;
  final String balanceTolerancePercent;
  final int maxSequenceBreak;
  final String selectedMultiOutlet;
  final PhaseLoad phaseLoad;

  final void Function(String uid) onAddSpareOutlet;
  final void Function(String uid) onDeleteSpareOutlet;
  final void Function(String newValue) onBalanceToleranceChanged;
  final void Function(String newValue) onMaxSequenceBreakChanged;
  final void Function(String uid) onMultiOutletPressed;

  PowerPatchViewModel({
    required this.selectedMultiOutlet,
    required this.rows,
    required this.phaseLoad,
    required this.balanceTolerancePercent,
    required this.onAddSpareOutlet,
    required this.onDeleteSpareOutlet,
    required this.onBalanceToleranceChanged,
    required this.onMaxSequenceBreakChanged,
    required this.maxSequenceBreak,
    required this.onMultiOutletPressed,
  });
}

abstract class PowerPatchRow {}

class LocationRow extends PowerPatchRow {
  final LocationModel location;
  final int multiCount;
  final void Function(bool value) onLockChanged;

  LocationRow({
    required this.location,
    required this.multiCount,
    required this.onLockChanged,
  });
}

class MultiOutletRow extends PowerPatchRow {
  final PowerMultiOutletModel multiOutlet;
  final List<PowerOutletVM> childOutlets;

  MultiOutletRow(this.multiOutlet, this.childOutlets);
}

class PowerOutletVM {
  final PowerOutletModel outlet;
  final List<FixtureOutletVM> fixtureVm;

  PowerOutletVM({
    required this.outlet,
    required this.fixtureVm,
  });
}

class FixtureOutletVM {
  final FixtureModel fixture;
  final FixtureTypeModel type;

  FixtureOutletVM({
    required this.fixture,
    required this.type,
  });
}
