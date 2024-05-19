import 'package:collection/collection.dart';

import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerOutletModel {
  final int phase;
  final PowerPatchModel child;
  final bool isSpare;
  final String multiOutletId;
  final String locationId;
  final int multiPatch;

  PowerOutletModel({
    required this.phase,
    required this.child,
    required this.multiOutletId,
    required this.multiPatch,
    required this.locationId,
    this.isSpare = false,
  });

  PowerOutletModel.spare({
    required this.phase,
    required this.multiOutletId,
    required this.multiPatch,
    required this.locationId,
  })  : isSpare = true,
        child = PowerPatchModel.empty();

  String lookupLocationId(Map<String, PowerMultiOutletModel> multiOutlets) {
    return multiOutlets[multiOutletId]?.locationId ?? '';
  }

  // static Map<String, List<PowerPatchModel>> getPatchesByLocationId({
  //   required List<PowerOutletModel> outlets,
  //   required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  // }) {
  //   return Map<String, List<PowerPatchModel>>.fromEntries(
  //     outlets
  //         .groupListsBy((outlet) => outlet.lookupLocationId(powerMultiOutlets))
  //         .entries
  //         .map(
  //           (entry) => MapEntry(
  //               entry.key, entry.value.map((outlet) => outlet.child).toList()),
  //         ),
  //   );
  // }

  PowerMultiOutletModel lookupPowerMultiOutlet(
      Map<String, PowerMultiOutletModel> multiOutlets) {
    return multiOutlets[multiOutletId] ?? const PowerMultiOutletModel.none();
  }

  PowerOutletModel copyWith({
    int? phase,
    PowerPatchModel? child,
    bool? isSpare,
    String? multiOutletId,
    String? locationId,
    int? multiPatch,
  }) {
    return PowerOutletModel(
      phase: phase ?? this.phase,
      child: child ?? this.child,
      isSpare: isSpare ?? this.isSpare,
      multiOutletId: multiOutletId ?? this.multiOutletId,
      locationId: locationId ?? this.locationId,
      multiPatch: multiPatch ?? this.multiPatch,
    );
  }
}
