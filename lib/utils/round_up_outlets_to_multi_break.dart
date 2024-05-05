import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

import 'package:sidekick/utils/get_multi_patch_from_index.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/utils/round_up_to_nearest_multi_break.dart';

List<PowerOutletModel> roundUpOutletsToNearestMultiBreak(
    List<PowerOutletModel> outlets) {
  final outletCount = outlets.length;
  final desiredCount = roundUpToNearestMultiBreak(outletCount);

  if (outletCount == desiredCount) {
    return outlets;
  }

  if (outletCount > desiredCount) {
    throw "Something has gone wrong. We shouldn't be calling roundUpOutletsToNearestMultiBreak when the outlet count is higher than the desired count.";
  }

  final diff = desiredCount - outletCount;
  final gapFillers = List<PowerOutletModel>.generate(
      diff,
      (index) => PowerOutletModel(
            uid: getUid(),
            child: PowerPatchModel.empty(),
            multiOutletId:
                '', // TODO: This likely needs to lookup an actual value,
            multiPatch: getMultiPatchFromIndex(outletCount - 1 + index),
            phase: getPhaseFromIndex(outletCount - 1 + index),
          ));

  return [
    ...outlets,
    ...gapFillers,
  ];
}
