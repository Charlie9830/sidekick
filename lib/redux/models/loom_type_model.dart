import 'dart:convert';

enum LoomType {
  custom,
  permanent,
}

class LoomTypeModel {
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
}
