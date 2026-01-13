// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class PowerRackTypeModel extends ModelCollectionMember {
  @override
  final String uid;

  final String name;
  final int ways;
  final int multiWayDivisor;

  int get multiOutletCount => (ways / multiWayDivisor).floor();

  PowerRackTypeModel(
      {required this.uid,
      required this.name,
      required this.ways,
      this.multiWayDivisor = 6 // Defaults to Socapex/6way Wieland,
      });

  PowerRackTypeModel copyWith({
    String? uid,
    String? name,
    int? ways,
    int? multiWayDivisor,
  }) {
    return PowerRackTypeModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      ways: ways ?? this.ways,
      multiWayDivisor: multiWayDivisor ?? this.multiWayDivisor,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'ways': ways,
      'multiWayDivisor': multiWayDivisor,
    };
  }

  factory PowerRackTypeModel.fromMap(Map<String, dynamic> map) {
    return PowerRackTypeModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      ways: map['ways'] as int,
      multiWayDivisor: map['multiWayDivisor'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerRackTypeModel.fromJson(String source) =>
      PowerRackTypeModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PowerRackTypeModel(uid: $uid, name: $name, ways: $ways, multiWayDivisor: $multiWayDivisor)';
  }

  @override
  bool operator ==(covariant PowerRackTypeModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.name == name &&
        other.ways == ways &&
        other.multiWayDivisor == multiWayDivisor;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        ways.hashCode ^
        multiWayDivisor.hashCode;
  }
}
