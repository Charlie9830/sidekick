// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class HoistControllerModel extends ModelCollectionMember {
  @override
  final String uid;
  final int ways;
  final String name;

  HoistControllerModel({
    required this.uid,
    required this.ways,
    required this.name,
  });

  HoistControllerModel copyWith({
    String? uid,
    int? ways,
    String? name,
    Map<int, String>? assignments,
  }) {
    return HoistControllerModel(
      uid: uid ?? this.uid,
      ways: ways ?? this.ways,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'ways': ways,
      'name': name,
    };
  }

  factory HoistControllerModel.fromMap(Map<String, dynamic> map) {
    return HoistControllerModel(
      uid: (map['uid'] ?? '') as String,
      ways: (map['ways'] ?? 0) as int,
      name: (map['name'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory HoistControllerModel.fromJson(String source) =>
      HoistControllerModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
