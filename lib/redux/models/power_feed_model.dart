// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class PowerFeedModel extends ModelCollectionMember {
  @override
  final String uid;
  final String powerSystemId;
  final String name;
  final int capacity;

  PowerFeedModel({
    required this.uid,
    required this.powerSystemId,
    required this.name,
    required this.capacity,
  });

  PowerFeedModel copyWith({
    String? uid,
    String? powerSystemId,
    String? name,
    int? capacity,
  }) {
    return PowerFeedModel(
      uid: uid ?? this.uid,
      powerSystemId: powerSystemId ?? this.powerSystemId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'powerSystemId': powerSystemId,
      'name': name,
      'capacity': capacity,
    };
  }

  factory PowerFeedModel.fromMap(Map<String, dynamic> map) {
    return PowerFeedModel(
      uid: map['uid'] as String,
      powerSystemId: map['powerSystemId'] as String,
      name: map['name'] as String,
      capacity: map['capacity'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerFeedModel.fromJson(String source) =>
      PowerFeedModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PowerFeedModel(uid: $uid, powerSystemId: $powerSystemId, name: $name, capacity: $capacity)';
  }
}
