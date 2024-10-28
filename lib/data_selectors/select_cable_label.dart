import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/screens/data_patch/data_patch.dart';

String selectCableLabel({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required CableModel cable,
  required bool includeUniverse,
}) {
  if (cable.isSpare) {
    return 'SP ${cable.spareIndex}';
  }

  if (cable.outletId.isEmpty) {
    return '';
  }

  if (cable.dataMultiId.isNotEmpty && cable.type == CableType.dmx) {
    return _selectSneakChildLabel(dataPatches[cable.outletId]);
  }

  return switch (cable.type) {
    CableType.socapex ||
    CableType.wieland6way =>
      powerMultiOutlets[cable.outletId]?.name ?? '',
    CableType.sneak => _selectSneakLabel(dataMultis[cable.outletId]),
    CableType.dmx =>
      _selectDMXLabel(dataPatches[cable.outletId], includeUniverse),
    CableType.unknown => throw UnimplementedError(),
  };
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

String _selectDMXLabel(DataPatchModel? patch, bool includeUniverse) {
  if (patch == null) {
    return '';
  }

  return includeUniverse ? patch.nameWithUniverse : patch.name;
}
