import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

String selectCableLabelHint({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, HoistModel> hoistOutlets,
  required Map<String, HoistMultiModel> hoistMultis,
  required CableModel cable,
}) {
  return switch (cable.type) {
    CableType.dmx => dataPatches[cable.outletId]?.name ?? '',
    _ => '',
  };
}
