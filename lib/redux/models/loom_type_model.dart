import 'dart:convert';

import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

enum LoomType {
  custom,
  permanent,
}

class LoomTypeModel with DiffComparable {
  final LoomType type;
  final double length;
  final String permanentComposition;

  LoomTypeModel({
    this.type = LoomType.custom,
    this.length = 0,
    this.permanentComposition = '',
  });

  const LoomTypeModel.blank()
      : type = LoomType.custom,
        length = 0,
        permanentComposition = '';

  bool checkIsValid(List<CableModel> children) {
    if (type != LoomType.permanent) {
      return true;
    }

    final composition = PermanentLoomComposition.byName[permanentComposition];

    if (composition == null) {
      return true;
    }

    return composition.isValidComposition(children);
  }

  String get humanFriendlyLength => convertToHumanFriendlyLength(length);

  LoomTypeModel copyWith({
    LoomType? type,
    double? length,
    String? permanentComposition,
  }) {
    return LoomTypeModel(
      type: type ?? this.type,
      length: length ?? this.length,
      permanentComposition: permanentComposition ?? this.permanentComposition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'length': length,
      'permanentComposition': permanentComposition,
    };
  }

  factory LoomTypeModel.fromMap(Map<String, dynamic> map) {
    return LoomTypeModel(
      type: LoomType.values.byName(map['type']),
      length: map['length']?.toDouble() ?? 0.0,
      permanentComposition: map['permanentComposition'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LoomTypeModel.fromJson(String source) =>
      LoomTypeModel.fromMap(json.decode(source));

  @override
  Map<PropertyDeltaName, Object> getDiffValues() => {
        PropertyDeltaName.loomLength: length,
        PropertyDeltaName.permanentComposition: permanentComposition,
        PropertyDeltaName.loomType: type,
      };

  static String convertToHumanFriendlyLength(double length) =>
      length.remainder(1) != 0
          ? length.toStringAsFixed(1)
          : length.toStringAsFixed(0);
}
