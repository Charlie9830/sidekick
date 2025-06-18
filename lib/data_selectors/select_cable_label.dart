import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

String selectCableLabel({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required CableModel cable,
  required bool forExcel,
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
      includeUniverseLabel: forExcel,
    );
  }

  return switch (cable.type) {
    CableType.socapex ||
    CableType.wieland6way =>
      powerMultiOutlets[cable.outletId]?.name ?? '',
    CableType.sneak => _selectSneakLabel(dataMultis[cable.outletId]),
    CableType.dmx => _selectDMXLabel(dataPatches[cable.outletId], forExcel),
    CableType.unknown => throw UnimplementedError(),
  };
}

String _selectSneakLabel(DataMultiModel? multi) {
  if (multi == null) {
    return '';
  }

  return multi.name;
}

String _selectSneakChildLabel(DataPatchModel? patch,
    {bool includeUniverseLabel = false}) {
  if (patch == null) {
    return '';
  }

  if (includeUniverseLabel == true) {
    return patch.nameWithUniverse;
  } else {
    return patch.name;
  }
}

String _selectDMXLabel(DataPatchModel? patch, bool includeUniverse) {
  if (patch == null) {
    return '';
  }

  if (includeUniverse == true) {
    return patch.nameWithUniverse;
  } else {
    return patch.name;
  }
}
