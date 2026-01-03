// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class PowerRackTemplateModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final int ways;
  final int multiCount;

  PowerRackTemplateModel({
    required this.uid,
    required this.name,
    required this.ways,
    this.multiCount = 6, // Hardcoded to Socapex/6 way wieland.
  });

  PowerRackTemplateModel copyWith({
    String? uid,
    String? name,
    int? ways,
    int? multiCount,
  }) {
    return PowerRackTemplateModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      ways: ways ?? this.ways,
      multiCount: multiCount ?? this.multiCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'ways': ways,
      'multiCount': multiCount,
    };
  }

  factory PowerRackTemplateModel.fromMap(Map<String, dynamic> map) {
    return PowerRackTemplateModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      ways: map['ways'] as int,
      multiCount: map['multiCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerRackTemplateModel.fromJson(String source) =>
      PowerRackTemplateModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PowerRackTemplateModel(uid: $uid, name: $name, ways: $ways, multiCount: $multiCount)';
  }

  @override
  bool operator ==(covariant PowerRackTemplateModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.name == name &&
        other.ways == ways &&
        other.multiCount == multiCount;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ name.hashCode ^ ways.hashCode ^ multiCount.hashCode;
  }
}
