import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerPatchViewModel {
  final List<PowerPatchModel> patches;
  final List<PowerOutletModel> outlets;

  final void Function() onGeneratePatch;
  final void Function(String uid) onRowSelected;
  final void Function(int index) onAddSpareOutlet;

  PowerPatchViewModel({
    required this.patches,
    required this.outlets,
    required this.onGeneratePatch,
    required this.onRowSelected,
    required this.onAddSpareOutlet,
  });
}
