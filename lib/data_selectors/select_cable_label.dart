import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

String selectCableLabel({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, HoistModel> hoistOutlets,
  required Map<String, HoistMultiModel> hoistMultis,
  required CableModel cable,
}) {
  if (cable.isSpare) {
    return 'SP ${cable.spareIndex + 1}';
  }

  if (cable.outletId.isEmpty) {
    return '';
  }

  if (cable.parentMultiId.isNotEmpty && cable.type == CableType.dmx) {
    return _selectSneakChildLabel(
      dataPatches[cable.outletId],
    );
  }

  return switch (cable.type) {
    CableType.socapex ||
    CableType.wieland6way =>
      powerMultiOutlets[cable.outletId]?.name ?? '',
    CableType.sneak => _selectSneakLabel(dataMultis[cable.outletId]),
    CableType.dmx => _selectDMXLabel(dataPatches[cable.outletId]),
    CableType.hoist => _selectSingleHoistLabel(hoistOutlets[cable.outletId]),
    CableType.hoistMulti => _selectHoistMultiLabel(hoistMultis[cable.outletId]),
    CableType.unknown => throw UnimplementedError(),
  };
}

String _selectSingleHoistLabel(HoistModel? hoist) {
  return hoist?.name ?? '';
}

String _selectHoistMultiLabel(HoistMultiModel? hoistMulti) {
  return hoistMulti?.name ?? '';
}

String _selectSneakLabel(DataMultiModel? multi) {
  if (multi == null) {
    return '';
  }

  return multi.name;
}

String _selectSneakChildLabel(DataPatchModel? patch) {
  if (patch == null) {
    return '';
  }

  return patch.universeLabel;
}

String _selectDMXLabel(DataPatchModel? patch) {
  if (patch == null) {
    return '';
  }

  return patch.universeLabel;
}
