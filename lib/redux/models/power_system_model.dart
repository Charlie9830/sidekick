// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class PowerSystemModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;

  PowerSystemModel({
    required this.uid,
    this.name = '',
  });

  static const String kDefaultUid = 'default';

  const PowerSystemModel.defaultSystem()
      : uid = kDefaultUid,
        name = 'Default';

  bool get isDefault => this == const PowerSystemModel.defaultSystem();

  PowerSystemModel copyWith({
    String? uid,
    String? name,
  }) {
    return PowerSystemModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
    };
  }

  factory PowerSystemModel.fromMap(Map<String, dynamic> map) {
    return PowerSystemModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerSystemModel.fromJson(String source) =>
      PowerSystemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PowerSystemModel(uid: $uid, name: $name)';

  @override
  bool operator ==(covariant PowerSystemModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid && other.name == name;
  }

  @override
  int get hashCode => uid.hashCode ^ name.hashCode;
}
