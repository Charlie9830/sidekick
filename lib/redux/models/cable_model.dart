import 'dart:convert';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

enum CableType {
  unknown,
  socapex,
  wieland6way,
  sneak,
  dmx,
}

const _ranking = {
  CableType.socapex: 0,
  CableType.wieland6way: 1,
  CableType.sneak: 2,
  CableType.dmx: 3,
  CableType.unknown: 4,
};

class CableModel extends ModelCollectionMember with DiffComparable {
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
  final int spareIndex;
  final String parentMultiId;

  CableModel({
    required this.uid,
    this.loomId = '',
    this.length = 0,
    required this.type,
    this.outletId = '',
    this.upstreamId = '',
    required this.locationId,
    this.notes = '',
    this.isSpare = false,
    this.spareIndex = 0,
    this.parentMultiId = '',
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
    int? spareIndex,
    String? parentMultiId,
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
      'locationId': locationId,
      'isSpare': isSpare,
      'spareIndex': spareIndex,
      'parentMultiId': parentMultiId,
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
      spareIndex: map['spareIndex'],
      parentMultiId: map['parentMultiId'] ?? '',
    );
  }

  bool get isMultiCable =>
      switch (type) { CableType.sneak => true, _ => false };

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

  @override
  Map<DiffPropertyName, Object> getDiffValues() => {
        DiffPropertyName.length: length,
        DiffPropertyName.notes: notes,
        DiffPropertyName.cableType: type,
        DiffPropertyName.isSpare: isSpare,
      };
}
