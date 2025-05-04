// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';

class LoomStockModel extends ModelCollectionMember {
  final double length;
  final String compositionName;
  final int qty;

  String get fullName => resolveFullName(compositionName, length);

  @override
  String get uid => fullName;

  LoomStockModel({
    required this.length,
    required this.compositionName,
    required this.qty,
  });

  LoomStockModel copyWith({
    double? length,
    String? compositionName,
    int? qty,
  }) {
    return LoomStockModel(
      length: length ?? this.length,
      compositionName: compositionName ?? this.compositionName,
      qty: qty ?? this.qty,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'length': length,
      'compositionName': compositionName,
      'qty': qty,
    };
  }

  factory LoomStockModel.fromMap(Map<String, dynamic> map) {
    return LoomStockModel(
      length: (map['length'] ?? 0.0) as double,
      compositionName: (map['compositionName'] ?? '') as String,
      qty: (map['qty'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomStockModel.fromJson(String source) =>
      LoomStockModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static String resolveFullName(String compositionName, double loomLength) =>
      '${LoomTypeModel.convertToHumanFriendlyLength(loomLength)}m $compositionName';
}
