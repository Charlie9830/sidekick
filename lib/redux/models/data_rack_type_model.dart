// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class DataRackTypeModel implements ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final int outletCount;
  final Map<int, int>
      dividers; // A Map of int, int. The Key represents the zero based index of a Channel, and the value represents the precedence of the Visual Divider below that channel. 0 is normal, 1 is light.

  const DataRackTypeModel({
    required this.uid,
    required this.name,
    required this.outletCount,
    required this.dividers,
  });

  DataRackTypeModel copyWith({
    String? uid,
    String? name,
    int? outletCount,
    Map<int, int>? dividers,
  }) {
    return DataRackTypeModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      outletCount: outletCount ?? this.outletCount,
      dividers: dividers ?? this.dividers,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'outletCount': outletCount,
      'dividers': dividers.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  factory DataRackTypeModel.fromMap(Map<String, dynamic> map) {
    return DataRackTypeModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      outletCount: map['outletCount'] as int,
      dividers: Map<int, int>.from(
        ((map['dividers'] ?? <String, int>{}) as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value as int),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory DataRackTypeModel.fromJson(String source) =>
      DataRackTypeModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
