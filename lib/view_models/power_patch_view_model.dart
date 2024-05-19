import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerPatchViewModel {
  final List<PowerPatchRow> rows;
  final String balanceTolerancePercent;
  final int maxSequenceBreak;
  final String selectedMultiOutlet;
  final PhaseLoad phaseLoad;

  final void Function() onGeneratePatch;
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
    required this.onGeneratePatch,
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

  LocationRow(this.location);
}

class MultiOutletRow extends PowerPatchRow {
  final PowerMultiOutletModel multiOutlet;
  final List<PowerOutletModel> childOutlets;

  MultiOutletRow(this.multiOutlet, this.childOutlets);
}
