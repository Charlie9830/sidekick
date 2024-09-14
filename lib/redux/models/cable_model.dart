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
  final String label;
  final String parentId;
  final CableType type;

  CableModel({
    required this.uid,
    this.parentId = '',
    this.label = '',
    required this.type,
  });

  CableModel copyWith({
    String? uid,
    String? parentId,
    CableType? type,
    String? label,
  }) {
    return CableModel(
      uid: uid ?? this.uid,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'parentId': parentId,
      'type': type.name,
      'label': label,
    };
  }

  factory CableModel.fromMap(Map<String, dynamic> map) {
    return CableModel(
      uid: map['uid'] ?? '',
      parentId: map['parentId'] ?? '',
      type: CableType.values.byName(map['type']),
      label: map['label'],
    );
  }

  @override
  String toString() {
    return '$label    $type    $parentId';
  }
}
