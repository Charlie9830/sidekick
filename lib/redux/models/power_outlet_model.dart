import 'dart:convert';

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

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'child': child.toMap(),
      'isSpare': isSpare,
      'multiOutletId': multiOutletId,
      'locationId': locationId,
      'multiPatch': multiPatch,
    };
  }

  factory PowerOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerOutletModel(
      phase: map['phase']?.toInt() ?? 0,
      child: PowerPatchModel.fromMap(map['child']),
      isSpare: map['isSpare'] ?? false,
      multiOutletId: map['multiOutletId'] ?? '',
      locationId: map['locationId'] ?? '',
      multiPatch: map['multiPatch']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerOutletModel.fromJson(String source) =>
      PowerOutletModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'PowerOutletModel(${child.fixtures.map((fixture) => fixture.fid).join(", ")})';
  }
}
