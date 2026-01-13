// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

class PowerRackModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final String note;
  final String typeId;
  final Map<int, String> assignments;

  PowerRackModel({
    required this.uid,
    required this.name,
    required this.note,
    required this.typeId,
    required this.assignments,
  });

  PowerRackModel copyWith({
    String? uid,
    String? name,
    String? note,
    String? typeId,
    Map<int, String>? assignments,
  }) {
    return PowerRackModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      note: note ?? this.note,
      typeId: typeId ?? this.typeId,
      assignments: assignments ?? this.assignments,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'note': note,
      'typeId': typeId,
      'assignments': assignments,
    };
  }

  factory PowerRackModel.fromMap(Map<String, dynamic> map) {
    return PowerRackModel(
        uid: map['uid'] as String,
        name: map['name'] as String,
        note: map['note'] as String,
        typeId: map['typeId'] as String,
        assignments: Map<int, String>.from(
          (map['assignments'] as Map<int, String>),
        ));
  }

  String toJson() => json.encode(toMap());

  factory PowerRackModel.fromJson(String source) =>
      PowerRackModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PowerRackModel(uid: $uid, name: $name, note: $note, typeId: $typeId)';
  }

  @override
  bool operator ==(covariant PowerRackModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.name == name &&
        other.note == note &&
        other.typeId == typeId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ name.hashCode ^ note.hashCode ^ typeId.hashCode;
  }
}
