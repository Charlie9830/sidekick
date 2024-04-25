import 'package:sidekick/redux/models/power_patch_model.dart';

class PowerOutletModel {
  final String uid;
  final int phase;
  final PowerPatchModel child;
  final bool isSpare;

  PowerOutletModel({
    required this.uid,
    required this.phase,
    required this.child,
    this.isSpare = false,
  });

  PowerOutletModel.spare({required this.uid, required this.phase})
      : isSpare = true,
        child = PowerPatchModel.empty();

  PowerOutletModel copyWith({
    String? uid,
    int? phase,
    PowerPatchModel? child,
    bool? isSpare,
  }) {
    return PowerOutletModel(
      uid: uid ?? this.uid,
      phase: phase ?? this.phase,
      child: child ?? this.child,
      isSpare: isSpare ?? this.isSpare,
    );
  }
}
