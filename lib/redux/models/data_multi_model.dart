import 'dart:convert';
import 'package:sidekick/redux/models/outlet.dart';

class DataMultiModel extends Outlet implements Comparable<DataMultiModel> {
  DataMultiModel({
    required String uid,
    required String locationId,
    String name = '',
    int number = 0,
  }) : super(uid: uid, locationId: locationId, number: number, name: name);

  @override
  DataMultiModel copyWith({
    String? uid,
    String? name,
    String? locationId,
    int? number,
  }) {
    return DataMultiModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      locationId: locationId ?? this.locationId,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'locationId': locationId,
      'number': number,
    };
  }

  factory DataMultiModel.fromMap(Map<String, dynamic> map) {
    return DataMultiModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      locationId: map['locationId'] ?? '',
      number: map['number']?.toInt() ?? 0,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataMultiModel &&
        other.uid == uid &&
        other.name == name &&
        other.number == number;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ name.hashCode ^ number.hashCode;
  }

  @override
  int compareTo(DataMultiModel other) {
    return number - other.number;
  }
}
