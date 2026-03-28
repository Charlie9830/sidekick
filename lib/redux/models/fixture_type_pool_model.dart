// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';

import 'package:sidekick/model_collection/model_collection_member.dart';

class FixtureTypePoolModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final Map<String, FixtureTypePoolEntryModel> items;

  FixtureTypePoolModel({
    required this.uid,
    required this.name,
    required this.items,
  });

  bool containsFixtureType(String fixtureTypeId) {
    return items.keys.contains(fixtureTypeId);
  }

  bool satisfiesMaxPoolQuantity(List<String> fixtureTypeIds) {
    final Map<String, int> candidateTypeCounts = fixtureTypeIds
        .fold<Map<String, int>>(
            {},
            (accum, value) => accum
              ..update(value, (existing) => existing + 1, ifAbsent: () => 1));

    final itemsByTypeId = items.values.groupListsBy((item) => item.typeId);

    return candidateTypeCounts.entries
        .map((entry) {
          final candidateTypeId = entry.key;
          final candidateTypeCount = entry.value;

          final poolItemQty =
              itemsByTypeId[candidateTypeId]?.firstOrNull?.qty ?? 0;

          return poolItemQty >= candidateTypeCount;
        })
        .toSet()
        .every((element) => element == true);
  }

  FixtureTypePoolModel copyWith({
    String? uid,
    String? name,
    Map<String, FixtureTypePoolEntryModel>? items,
  }) {
    return FixtureTypePoolModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'items': items.values.map((x) => x.toMap()).toList(),
    };
  }

  factory FixtureTypePoolModel.fromMap(Map<String, dynamic> map) {
    return FixtureTypePoolModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      items: ((map['items'] ?? []) as List<dynamic>)
          .map((x) => FixtureTypePoolEntryModel.fromMap(x))
          .toModelMap(),
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureTypePoolModel.fromJson(String source) =>
      FixtureTypePoolModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

class FixtureTypePoolEntryModel extends ModelCollectionMember {
  @override
  String get uid => typeId;
  final String typeId;
  final int qty;

  FixtureTypePoolEntryModel({
    required this.typeId,
    required this.qty,
  });

  FixtureTypePoolEntryModel copyWith({
    String? typeId,
    int? qty,
  }) {
    return FixtureTypePoolEntryModel(
      typeId: typeId ?? this.typeId,
      qty: qty ?? this.qty,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'typeId': typeId,
      'qty': qty,
    };
  }

  factory FixtureTypePoolEntryModel.fromMap(Map<String, dynamic> map) {
    return FixtureTypePoolEntryModel(
      typeId: map['typeId'] as String,
      qty: map['qty'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureTypePoolEntryModel.fromJson(String source) =>
      FixtureTypePoolEntryModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
