// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class DataRackModel implements ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final String notes;
  final String typeId;

  DataRackModel({
    required this.uid,
    required this.name,
    required this.notes,
    required this.typeId,
  });

  DataRackModel copyWith({
    String? uid,
    String? name,
    String? notes,
    String? typeId,
    Map<int, int>? dividers,
  }) {
    return DataRackModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      typeId: typeId ?? this.typeId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'notes': notes,
      'typeId': typeId,
    };
  }

  factory DataRackModel.fromMap(Map<String, dynamic> map) {
    return DataRackModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String,
      typeId: map['typeId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataRackModel.fromJson(String source) =>
      DataRackModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
