import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

class SetDataPatches {
  final Map<String, DataPatchModel> patches;

  SetDataPatches(this.patches);
}

class AppendSelectedMultiChannelId {
  final String value;

  AppendSelectedMultiChannelId(this.value);
}

class SetSelectedPowerMultiOutletIds {
  final Set<String> value;

  SetSelectedPowerMultiOutletIds(this.value);
}

class SetSelectedPowerMultiChannelIds {
  final Set<String> value;

  SetSelectedPowerMultiChannelIds(this.value);
}

class SetDataMultis {
  final Map<String, DataMultiModel> multis;

  SetDataMultis(this.multis);
}

class SetSelectedMultiOutlet {
  final String uid;

  SetSelectedMultiOutlet(this.uid);
}

class SetPowerMultiOutlets {
  final Map<String, PowerMultiOutletModel> multiOutlets;

  SetPowerMultiOutlets(this.multiOutlets);
}

class SelectPatchRow {
  final String uid;

  SelectPatchRow(this.uid);
}

class SetBalanceTolerance {
  final String value;

  SetBalanceTolerance(this.value);
}

class SetMaxSequenceBreak {
  final String value;

  SetMaxSequenceBreak(this.value);
}

class CommitLocationPowerPatch {
  final LocationModel location;

  CommitLocationPowerPatch(this.location);
}
