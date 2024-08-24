import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:sidekick/redux/models/cable_model.dart';

class LoomModel {
  final String uid;
  final String locationId;
  final List<CableModel> children;
  final String name;

  LoomModel({
    this.uid = '',
    this.locationId = '',
    this.children = const [],
    this.name = '',
  });

  LoomModel copyWith({
    String? uid,
    String? locationId,
    List<CableModel>? children,
    String? name,
  }) {
    return LoomModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      children: children ?? this.children,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'locationId': locationId,
      'children': children.map((x) => x.toMap()).toList(),
      'name': name,
    };
  }

  factory LoomModel.fromMap(Map<String, dynamic> map) {
    return LoomModel(
      uid: map['uid'] ?? '',
      locationId: map['locationId'] ?? '',
      children: List<CableModel>.from(
          map['children']?.map((x) => CableModel.fromMap(x))),
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomModel.fromJson(String source) =>
      LoomModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LoomModel(uid: $uid, locationId: $locationId, children: $children, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoomModel &&
        other.uid == uid &&
        other.locationId == locationId &&
        listEquals(other.children, children) &&
        other.name == name;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        locationId.hashCode ^
        children.hashCode ^
        name.hashCode;
  }
}
