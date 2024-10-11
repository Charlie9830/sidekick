import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

String selectCableTypeLabel({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required CableModel cable,
}) {
  if (cable.type == CableType.dmx) {
    final patch = dataPatches[cable.outletId];

    if (patch == null) {
      return '';
    }

    if (patch.multiId.isEmpty) {
      return _humanFriendlyType(cable.type);
    }

    // If a child of a Sneak, Return a slightly different nomenclature.
    return ' - Data';
  }

  return _humanFriendlyType(cable.type);
}

String _humanFriendlyType(CableType type) {
  return switch (type) {
    CableType.dmx => 'DMX',
    CableType.sneak => 'Sneak',
    CableType.socapex => 'Soca',
    CableType.wieland6way => '6way',
    CableType.unknown => 'Unknown',
  };
}