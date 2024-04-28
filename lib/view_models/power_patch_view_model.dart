import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerPatchViewModel {
  final List<PowerPatchModel> patches;
  final List<PowerOutletModel> outlets;
  final String balanceTolerancePercent;
  final int maxSequenceBreak;

  final void Function() onGeneratePatch;
  final void Function(String uid) onRowSelected;
  final void Function(int index) onAddSpareOutlet;
  final void Function(int index) onDeleteSpareOutlet;
  final void Function(String newValue) onBalanceToleranceChanged;
  final void Function(String newValue) onMaxSequenceBreakChanged;

  PowerPatchViewModel({
    required this.balanceTolerancePercent,
    required this.patches,
    required this.outlets,
    required this.onGeneratePatch,
    required this.onRowSelected,
    required this.onAddSpareOutlet,
    required this.onDeleteSpareOutlet,
    required this.onBalanceToleranceChanged,
    required this.onMaxSequenceBreakChanged,
    required this.maxSequenceBreak,
  });
}
