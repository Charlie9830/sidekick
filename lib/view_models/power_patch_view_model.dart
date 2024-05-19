import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerPatchViewModel {
  final Map<PowerMultiOutletModel, List<PowerOutletModel>> multiOutlets;
  final String balanceTolerancePercent;
  final int maxSequenceBreak;
  final String selectedMultiOutlet;

  final void Function() onGeneratePatch;
  final void Function(String uid) onAddSpareOutlet;
  final void Function(String uid) onDeleteSpareOutlet;
  final void Function(String newValue) onBalanceToleranceChanged;
  final void Function(String newValue) onMaxSequenceBreakChanged;
  final void Function(String uid) onMultiOutletPressed;

  PowerPatchViewModel({
    required this.selectedMultiOutlet,
    required this.multiOutlets,
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
