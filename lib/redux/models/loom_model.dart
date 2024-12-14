// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';

enum LoomClass {
  feeder,
  extension,
}

class LoomModel extends ModelCollectionMember {
  @override
  final String uid;
  final String locationId;
  final LoomTypeModel type;

  // enum
  final LoomClass loomClass;
  final bool isDrop;

  LoomModel({
    this.uid = '',
    this.locationId = '',
    this.type = const LoomTypeModel.blank(),
    this.loomClass = LoomClass.feeder,
    this.isDrop = false,
  });

  LoomModel copyWith({
    String? uid,
    String? locationId,
    Set<String>? secondaryLocationIds,
    LoomTypeModel? type,
    LoomClass? loomClass,
    bool? isDrop,
  }) {
    return LoomModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      type: type ?? this.type,
      loomClass: loomClass ?? this.loomClass,
      isDrop: isDrop ?? this.isDrop,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'locationId': locationId,
      'type': type.toMap(),
      'loomClass': loomClass.index,
      'isDrop': isDrop,
    };
  }

  factory LoomModel.fromMap(Map<String, dynamic> map) {
    return LoomModel(
      uid: (map['uid'] ?? '') as String,
      locationId: map['locationId'] ?? '',
      type: LoomTypeModel.fromMap(map['type'] as Map<String, dynamic>),
      loomClass: LoomClass.values[(map['loomClass'] ?? 0) as int],
      isDrop: (map['isDrop'] ?? false) as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomModel.fromJson(String source) =>
      LoomModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LoomModel(uid: $uid, locationId: $locationId)';
  }

  static double matchLength(LocationModel? location) {
    if (location == null) {
      return 0;
    }

    final colorToLengthLookup = <Color, double>{
      NamedColors.yellow: 50,
      NamedColors.red: 45,
      NamedColors.white: 40,
      NamedColors.blue: 35,
      NamedColors.orange: 30,
      NamedColors.brown: 25,
      NamedColors.grey: 20,
      NamedColors.purple: 0,
    };

    return colorToLengthLookup[location.color] ?? 0;
  }
}
