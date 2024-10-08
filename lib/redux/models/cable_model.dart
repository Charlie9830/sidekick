import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

enum CableType {
  unknown,
  socapex,
  wieland6way,
  sneak,
  dmx,
}

class CableModel extends ModelCollectionMember {
  @override
  final String uid;
  final double length;
  final String loomId;
  final String outletId;
  final String locationId;
  final String upstreamId;
  final String notes;
  final CableType type;
  final bool isSpare;
  final bool isDropper;
  final int spareIndex;

  CableModel({
    required this.uid,
    this.loomId = '',
    this.length = 0,
    required this.type,
    this.outletId = '',
    this.upstreamId = '',
    this.locationId = '',
    this.notes = '',
    this.isSpare = false,
    this.isDropper = false,
    this.spareIndex = 0,
  });

  CableModel copyWith({
    String? uid,
    double? length,
    String? loomId,
    String? outletId,
    String? locationId,
    String? upstreamId,
    String? notes,
    CableType? type,
    bool? isSpare,
    bool? isDropper,
    int? spareIndex,
  }) {
    return CableModel(
      uid: uid ?? this.uid,
      length: length ?? this.length,
      loomId: loomId ?? this.loomId,
      outletId: outletId ?? this.outletId,
      locationId: locationId ?? this.locationId,
      upstreamId: upstreamId ?? this.upstreamId,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isSpare: isSpare ?? this.isSpare,
      isDropper: isDropper ?? this.isDropper,
      spareIndex: spareIndex ?? this.spareIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'length': length,
      'loomId': loomId,
      'outletId': outletId,
      'upstreamId': upstreamId,
      'type': type.name,
      'notes': notes,
      'locationId': locationId,
      'isSpare': isSpare,
      'isDropper': isDropper,
      'spareIndex': spareIndex,
    };
  }

  factory CableModel.fromMap(Map<String, dynamic> map) {
    return CableModel(
      uid: map['uid'] ?? '',
      length: map['length'] ?? '',
      loomId: map['loomId'] ?? '',
      outletId: map['outletId'] ?? '',
      upstreamId: map['upstreamId'] ?? '',
      locationId: map['locationId'] ?? '',
      notes: map['notes'] ?? '',
      type: CableType.values.byName(map['type']),
      isSpare: map['isSpare'],
      isDropper: map['isDropper'],
      spareIndex: map['spareIndex'],
    );
  }

  @override
  String toString() {
    return '    $type    $loomId';
  }

  String toJson() => json.encode(toMap());

  factory CableModel.fromJson(String source) =>
      CableModel.fromMap(json.decode(source));
}
