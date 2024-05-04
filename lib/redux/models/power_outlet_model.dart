import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerOutletModel {
  final String uid;
  final int phase;
  final PowerPatchModel child;
  final bool isSpare;
  final int multiOutlet;
  final int multiPatch;

  PowerOutletModel({
    required this.uid,
    required this.phase,
    required this.child,
    required this.multiOutlet,
    required this.multiPatch,
    this.isSpare = false,
  });

  PowerOutletModel.spare(
      {required this.uid,
      required this.phase,
      required this.multiOutlet,
      required this.multiPatch})
      : isSpare = true,
        child = PowerPatchModel.empty();

  PowerOutletModel copyWith({
    String? uid,
    int? phase,
    PowerPatchModel? child,
    bool? isSpare,
    int? multiOutlet,
    int? multiPatch,
  }) {
    return PowerOutletModel(
      uid: uid ?? this.uid,
      phase: phase ?? this.phase,
      child: child ?? this.child,
      isSpare: isSpare ?? this.isSpare,
      multiOutlet: multiOutlet ?? this.multiOutlet,
      multiPatch: multiPatch ?? this.multiPatch,
    );
  }

  String getAssociatedLocations() {
    return child.fixtures
        .map((fixture) => fixture.location.trim())
        .where((location) => location.trim().isNotEmpty)
        .toSet()
        .join(", ");
  }
}
