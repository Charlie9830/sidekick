// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

enum LoomClass {
  feeder,
  extension,
}

class LoomModel extends ModelCollectionMember with DiffComparable {
  @override
  final String uid;
  final LoomTypeModel type;
  final String name;

  // enum
  final LoomClass loomClass;
  final bool isDrop;

  LoomModel({
    this.uid = '',
    this.type = const LoomTypeModel.blank(),
    this.loomClass = LoomClass.feeder,
    this.isDrop = false,
    this.name = '',
  });

  LoomModel copyWith({
    String? uid,
    LoomTypeModel? type,
    LoomClass? loomClass,
    bool? isDrop,
    String? name,
  }) {
    return LoomModel(
      uid: uid ?? this.uid,
      type: type ?? this.type,
      loomClass: loomClass ?? this.loomClass,
      isDrop: isDrop ?? this.isDrop,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'type': type.toMap(),
      'loomClass': loomClass.index,
      'isDrop': isDrop,
      'name': name,
    };
  }

  factory LoomModel.fromMap(Map<String, dynamic> map) {
    return LoomModel(
      uid: (map['uid'] ?? '') as String,
      type: LoomTypeModel.fromMap(map['type'] as Map<String, dynamic>),
      loomClass: LoomClass.values[(map['loomClass'] ?? 0) as int],
      isDrop: (map['isDrop'] ?? false) as bool,
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
  Map<DiffPropertyName, Object> getDiffValues() => {
        DiffPropertyName.length: type,
        DiffPropertyName.loomClass: loomClass,
        DiffPropertyName.loomType: type,
        DiffPropertyName.isDrop: isDrop,
      };
}
