import 'dart:convert';
import 'package:sidekick/redux/models/outlet.dart';

class DataMultiModel extends Outlet implements Comparable<DataMultiModel> {
  final bool isDetached;

  DataMultiModel({
    required String uid,
    required String locationId,
    String name = '',
    int number = 0,
    this.isDetached = false,
  }) : super(uid: uid, locationId: locationId, number: number, name: name);

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
