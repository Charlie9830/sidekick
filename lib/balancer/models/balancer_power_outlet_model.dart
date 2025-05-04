import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';


class BalancerPowerOutletModel {
  final int phase;
  final BalancerPowerPatchModel child;
  final bool isSpare;
  final String multiOutletId;
  final String locationId;
  final int multiPatch;

  BalancerPowerOutletModel({
    required this.phase,
    required this.child,
    required this.multiOutletId,
    required this.multiPatch,
    required this.locationId,
    this.isSpare = false,
  });
  
  BalancerPowerOutletModel copyWith({
    int? phase,
    BalancerPowerPatchModel? child,
    bool? isSpare,
    String? multiOutletId,
    String? locationId,
    int? multiPatch,
  }) {
    return BalancerPowerOutletModel(
      phase: phase ?? this.phase,
      child: child ?? this.child,
      isSpare: isSpare ?? this.isSpare,
      multiOutletId: multiOutletId ?? this.multiOutletId,
      locationId: locationId ?? this.locationId,
      multiPatch: multiPatch ?? this.multiPatch,
    );
  }
}
