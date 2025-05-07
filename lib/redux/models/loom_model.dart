// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LoomModel extends ModelCollectionMember with DiffComparable {
  @override
  final String uid;
  final LoomTypeModel type;
  final String name;

  LoomModel({
    this.uid = '',
    this.type = const LoomTypeModel.blank(),
    this.name = '',
  });

  LoomModel copyWith({
    String? uid,
    LoomTypeModel? type,
    String? name,
  }) {
    return LoomModel(
      uid: uid ?? this.uid,
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'type': type.toMap(),
      'name': name,
    };
  }

  factory LoomModel.fromMap(Map<String, dynamic> map) {
    return LoomModel(
      uid: (map['uid'] ?? '') as String,
      type: LoomTypeModel.fromMap(map['type'] as Map<String, dynamic>),
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomModel.fromJson(String source) =>
      LoomModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LoomModel(uid: $uid)';
  }

  @override
  Map<DeltaPropertyName, Object> getDiffValues() => {
        DeltaPropertyName.length: type.length,
        DeltaPropertyName.loomType: type,
        DeltaPropertyName.permanentComposition: type.permanentComposition,
        DeltaPropertyName.name: name,
      };
}
