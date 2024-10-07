import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';

class LoomModel extends ModelCollectionMember {
  @override
  final String uid;
  final Set<String> locationIds;
  final String name;
  final LoomTypeModel type;
  final List<String> childrenIds;

  LoomModel({
    this.uid = '',
    this.locationIds = const {},
    this.name = '',
    this.type = const LoomTypeModel.blank(),
    this.childrenIds = const [],
  });

  LoomModel copyWith({
    String? uid,
    Set<String>? locationIds,
    String? name,
    LoomTypeModel? type,
    List<String>? childrenIds,
  }) {
    return LoomModel(
      uid: uid ?? this.uid,
      locationIds: locationIds ?? this.locationIds,
      name: name ?? this.name,
      type: type ?? this.type,
      childrenIds: childrenIds ?? this.childrenIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'locationIds': locationIds.toList(),
      'name': name,
      'type': type.toMap(),
      'childrenIds': childrenIds,
    };
  }

  factory LoomModel.fromMap(Map<String, dynamic> map) {
    return LoomModel(
      uid: map['uid'] ?? '',
      locationIds: Set<String>.from(map['locationIds']),
      name: map['name'] ?? '',
      type: LoomTypeModel.fromMap(map['type']),
      childrenIds: List<String>.from(map['childrenIds']),
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomModel.fromJson(String source) =>
      LoomModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LoomModel(uid: $uid, locationId: $locationIds, name: $name)';
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
