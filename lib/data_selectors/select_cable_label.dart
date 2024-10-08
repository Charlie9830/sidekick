import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

String selectCableLabel({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required CableModel cable,
}) {
  if (cable.outletId.isEmpty) {
    return '';
  }

  if (cable.isSpare) {
    return 'SP ${cable.spareIndex}';
  }

  return switch (cable.type) {
    CableType.socapex ||
    CableType.wieland6way =>
      powerMultiOutlets[cable.outletId]?.name ?? '',
    CableType.sneak => dataMultis[cable.outletId]?.name ?? '',
    CableType.dmx => dataPatches[cable.outletId]?.name ?? '',
    CableType.unknown => throw UnimplementedError(),
  };
}
