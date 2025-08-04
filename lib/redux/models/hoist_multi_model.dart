import 'dart:convert';
import 'package:sidekick/redux/models/outlet.dart';

class HoistMultiModel extends Outlet implements Comparable<HoistMultiModel> {
  final bool isDetached;

  HoistMultiModel({
    required super.uid,
    required super.locationId,
    super.number = 0,
    super.name = '',
    this.isDetached = false,
  });

  @override
  int compareTo(HoistMultiModel other) {
    return number - other.number;
  }

  @override
  Outlet copyWith(
      {String? uid,
      String? locationId,
      String? name,
      int? number,
      bool? isDetached}) {
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
