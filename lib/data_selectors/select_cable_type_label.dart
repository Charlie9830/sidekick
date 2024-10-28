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

    if (cable.dataMultiId.isEmpty) {
      // Top Level / Parent Cable.
      return _humanFriendlyType(cable.type);
    } else {
      return _humanFriendlyType(cable.type, isSneakChild: true);
    }
  }

  return _humanFriendlyType(cable.type);
}

String _humanFriendlyType(CableType type, {bool isSneakChild = false}) {
  if (isSneakChild) {
    return '  Data';
  }

  return switch (type) {
    CableType.dmx => 'DMX',
    CableType.sneak => 'Sneak',
    CableType.socapex => 'Soca',
    CableType.wieland6way => '6way',
    CableType.unknown => 'Unknown',
  };
}
