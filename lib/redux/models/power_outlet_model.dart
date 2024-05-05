import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerOutletModel {
  final String uid;
  final int phase;
  final PowerPatchModel child;
  final bool isSpare;
  final String multiOutletId;
  final int multiPatch;

  PowerOutletModel({
    required this.uid,
    required this.phase,
    required this.child,
    required this.multiOutletId,
    required this.multiPatch,
    this.isSpare = false,
  });

  PowerOutletModel.spare(
      {required this.uid,
      required this.phase,
      required this.multiOutletId,
      required this.multiPatch})
      : isSpare = true,
        child = PowerPatchModel.empty();

  String lookupLocationId(Map<String, PowerMultiOutletModel> multiOutlets) {
    return multiOutlets[multiOutletId]?.locationId ?? '';
  }

  static Map<String, List<PowerPatchModel>> getPatchesByLocationId({
    required List<PowerOutletModel> outlets,
    required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  }) {
    return Map<String, List<PowerPatchModel>>.fromEntries(
      outlets
          .groupListsBy((outlet) => outlet.lookupLocationId(powerMultiOutlets))
          .entries
          .map(
            (entry) => MapEntry(
                entry.key, entry.value.map((outlet) => outlet.child).toList()),
          ),
    );
  }

  PowerMultiOutletModel lookupPowerMultiOutlet(
      Map<String, PowerMultiOutletModel> multiOutlets) {
    return multiOutlets[multiOutletId] ?? const PowerMultiOutletModel.none();
  }

  PowerOutletModel copyWith({
    String? uid,
    int? phase,
    PowerPatchModel? child,
    bool? isSpare,
    String? multiOutletId,
    int? multiPatch,
  }) {
    return PowerOutletModel(
      uid: uid ?? this.uid,
      phase: phase ?? this.phase,
      child: child ?? this.child,
      isSpare: isSpare ?? this.isSpare,
      multiOutletId: multiOutletId ?? this.multiOutletId,
      multiPatch: multiPatch ?? this.multiPatch,
    );
  }
}
