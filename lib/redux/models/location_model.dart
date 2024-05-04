import 'dart:convert';
import 'dart:ui';

class LocationModel {
  String name;
  Color color;
  String multiPrefix;
  LocationModel({
    this.name = '',
    required this.color,
    this.multiPrefix = '',
  });

  LocationModel copyWith({
    String? name,
    Color? color,
    String? multiPrefix,
  }) {
    return LocationModel(
      name: name ?? this.name,
      color: color ?? this.color,
      multiPrefix: multiPrefix ?? this.multiPrefix,
    );
  }

  String getPrefixedPowerMulti(int multiOutlet) {
    return '$multiPrefix$multiOutlet';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color.value,
      'multiPrefix': multiPrefix,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      name: map['name'] ?? '',
      color: Color(map['color']),
      multiPrefix: map['multiPrefix'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'LocationModel(name: $name, color: $color, multiPrefix: $multiPrefix)';
}
