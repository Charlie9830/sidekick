// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';

enum CableType {
  unknown,
  socapex,
  wieland6way,
  sneak,
  dmx,
  hoist,
  hoistMulti,
}

enum CableClass {
  feeder,
  extension,
  dropper,
  none, // Used as Sentinel value.
}

const _ranking = {
  CableType.socapex: 0,
  CableType.wieland6way: 1,
  CableType.sneak: 2,
  CableType.dmx: 3,
  CableType.unknown: 4,
  CableType.hoist: 5,
  CableType.hoistMulti: 6,
};

class CableModel extends ModelCollectionMember {
  @override
  final String uid;
  final double length;
  final String loomId;
  final String outletId;
  final String upstreamId;
  final bool isDropper;
  final String notes;
  final CableType type;
  final bool isSpare;
  final int spareIndex;
  final String parentMultiId;

  CableModel({
    required this.uid,
    this.loomId = '',
    this.length = 0,
    required this.type,
    this.outletId = '',
    this.upstreamId = '',
    this.notes = '',
    this.isSpare = false,
    this.spareIndex = 0,
    this.parentMultiId = '',
    this.isDropper = false,
  });

  CableModel copyWith({
    String? uid,
    double? length,
    String? loomId,
    String? outletId,
    String? upstreamId,
    bool? isDropper,
    String? notes,
    CableType? type,
    bool? isSpare,
    int? spareIndex,
    String? parentMultiId,
  }) {
    return CableModel(
      uid: uid ?? this.uid,
      length: length ?? this.length,
      loomId: loomId ?? this.loomId,
      outletId: outletId ?? this.outletId,
      upstreamId: upstreamId ?? this.upstreamId,
      isDropper: isDropper ?? this.isDropper,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isSpare: isSpare ?? this.isSpare,
      spareIndex: spareIndex ?? this.spareIndex,
      parentMultiId: parentMultiId ?? this.parentMultiId,
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
      'isSpare': isSpare,
      'spareIndex': spareIndex,
      'parentMultiId': parentMultiId,
      'isDropper': isDropper,
    };
  }

  factory CableModel.fromMap(Map<String, dynamic> map) {
    return CableModel(
      uid: map['uid'] ?? '',
      length: map['length'] ?? '',
      loomId: map['loomId'] ?? '',
      outletId: map['outletId'] ?? '',
      upstreamId: map['upstreamId'] ?? '',
      notes: map['notes'] ?? '',
      type: CableType.values.byName(map['type']),
      isSpare: map['isSpare'],
      spareIndex: map['spareIndex'],
      parentMultiId: map['parentMultiId'] ?? '',
      isDropper: map['isDropper'] ?? false,
    );
  }

  bool get isMultiCable =>
      switch (type) { CableType.sneak => true, _ => false };

  bool get isExtension => upstreamId.isNotEmpty;

  CableClass get cableClass {
    if (isDropper) {
      return CableClass.dropper;
    }

    return upstreamId.isEmpty ? CableClass.feeder : CableClass.extension;
  }

  String get humanFriendlyLength =>
      LoomTypeModel.convertToHumanFriendlyLength(length);

  @override
  String toString() {
    return '    $type    $loomId';
  }

  String toJson() => json.encode(toMap());

  factory CableModel.fromJson(String source) =>
      CableModel.fromMap(json.decode(source));

  static int compareByType(CableModel a, CableModel b) {
    return _ranking[a.type]! - _ranking[b.type]!;
  }
}
