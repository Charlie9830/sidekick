// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

class NamedColorModel {
  final String name;
  final Color color;

  const NamedColorModel({
    required this.name,
    required this.color,
  });

  NamedColorModel copyWith({
    String? name,
    Color? color,
  }) {
    return NamedColorModel(
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'color': color.toARGB32(),
    };
  }

  factory NamedColorModel.fromMap(Map<String, dynamic> map) {
    return NamedColorModel(
      name: (map['name'] ?? '') as String,
      color: Color(map['color'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory NamedColorModel.fromJson(String source) =>
      NamedColorModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
