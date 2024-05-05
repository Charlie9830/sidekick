import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/view_models/power_patch_row_view_model.dart';

class PowerPatchViewModel {
  final List<PowerPatchRowViewModel> rowViewModels;
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
    required this.rowViewModels,
    required this.onGeneratePatch,
    required this.onRowSelected,
    required this.onAddSpareOutlet,
    required this.onDeleteSpareOutlet,
    required this.onBalanceToleranceChanged,
    required this.onMaxSequenceBreakChanged,
    required this.maxSequenceBreak,
  });
}
