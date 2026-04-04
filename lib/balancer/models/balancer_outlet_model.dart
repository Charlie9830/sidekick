// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/balancer/models/patch_contents.dart';

class BalancerOutletModel {
  final int phase;
  final bool isSpare;
  final PatchContents contents;
  final String multiOutletId;
  final String locationId;
  final int multiPatch;
  final String fixtureTypePoolId;

  BalancerOutletModel({
    required this.phase,
    required this.contents,
    required this.multiOutletId,
    required this.multiPatch,
    required this.locationId,
    this.isSpare = false,
    required this.fixtureTypePoolId,
  });

  BalancerOutletModel copyWith({
    int? phase,
    PatchContents? contents,
    bool? isSpare,
    String? multiOutletId,
    String? locationId,
    int? multiPatch,
    String? fixtureTypePoolId,
  }) {
    return BalancerOutletModel(
      phase: phase ?? this.phase,
      contents: contents ?? this.contents,
      isSpare: isSpare ?? this.isSpare,
      multiOutletId: multiOutletId ?? this.multiOutletId,
      locationId: locationId ?? this.locationId,
      multiPatch: multiPatch ?? this.multiPatch,
      fixtureTypePoolId: fixtureTypePoolId ?? this.fixtureTypePoolId,
    );
  }
}
