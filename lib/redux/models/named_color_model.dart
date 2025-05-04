// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

class NamedColorModel {
  final String name;
  final Color color;
  final double defaultLength;

  const NamedColorModel({
    required this.name,
    required this.color,
    required this.defaultLength,
  });

  NamedColorModel copyWith({
    String? name,
    Color? color,
    double? defaultLength,
  }) {
    return NamedColorModel(
      name: name ?? this.name,
      color: color ?? this.color,
      defaultLength: defaultLength ?? this.defaultLength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'color': color.toARGB32(),
      'defaultLength': defaultLength,
    };
  }

  factory NamedColorModel.fromMap(Map<String, dynamic> map) {
    return NamedColorModel(
      name: (map['name'] ?? '') as String,
      color: Color(map['color'] as int),
      defaultLength: map['defaultLength'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory NamedColorModel.fromJson(String source) =>
      NamedColorModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
