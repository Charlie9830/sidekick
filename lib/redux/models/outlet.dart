import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

abstract class Outlet extends ModelCollectionMember {
  @override
  final String uid;
  final String locationId;
  final int number;
  final String name;

  const Outlet({
    required this.uid,
    required this.locationId,
    required this.number,
    required this.name,
  });

  Outlet copyWith();
}

sealed class MultiOutlet extends Outlet {
  final bool isDetached;

  MultiOutlet({
    required super.uid,
    required super.locationId,
    required super.number,
    required super.name,
    required this.isDetached,
  });

  @override
  MultiOutlet copyWith({
    bool? isDetached,
  }) {
    return switch (this) {
      DataMultiModel o => o.copyWith(isDetached: isDetached ?? this.isDetached),
      HoistMultiModel o => o.copyWith(isDetached: isDetached ?? this.isDetached)
    };
  }
}

class DataMultiModel extends MultiOutlet implements Comparable<DataMultiModel> {
  DataMultiModel({
    required String uid,
    required String locationId,
    String name = '',
    int number = 0,
    bool isDetached = false,
  }) : super(
            uid: uid,
            locationId: locationId,
            number: number,
            name: name,
            isDetached: isDetached);

  @override
  DataMultiModel copyWith({
    String? uid,
    String? name,
    String? locationId,
    int? number,
    bool? isDetached,
  }) {
    return DataMultiModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
      isDetached: isDetached ?? this.isDetached,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'number': number,
      'isDetached': isDetached,
    };
  }

  factory DataMultiModel.fromMap(Map<String, dynamic> map) {
    return DataMultiModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
      isDetached: map['isDetached'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataMultiModel.fromJson(String source) =>
      DataMultiModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataMultiModel(uid: $uid, name: $name, number: $number)';
  }

  @override
  int compareTo(DataMultiModel other) {
    return number - other.number;
  }
}

class HoistMultiModel extends MultiOutlet
    implements Comparable<HoistMultiModel> {
  HoistMultiModel({
    required super.uid,
    required super.locationId,
    super.number = 0,
    super.name = '',
    super.isDetached = false,
  });

  @override
  int compareTo(HoistMultiModel other) {
    return number - other.number;
  }

  @override
  MultiOutlet copyWith({
    String? uid,
    String? locationId,
    String? name,
    int? number,
    bool? isDetached,
  }) {
    return HoistMultiModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
      name: name ?? this.name,
      isDetached: isDetached ?? this.isDetached,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'number': number,
      'isDetached': isDetached,
    };
  }

  factory HoistMultiModel.fromMap(Map<String, dynamic> map) {
    return HoistMultiModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
      isDetached: map['isDetached'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory HoistMultiModel.fromJson(String source) =>
      HoistMultiModel.fromMap(json.decode(source));
}
