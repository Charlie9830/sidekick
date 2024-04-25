import 'dart:convert';

class FixtureModeModel {
  final String name;
  FixtureModeModel({
    this.name = '',
  });

  const FixtureModeModel.unknown() : name = '';

  FixtureModeModel copyWith({
    String? name,
  }) {
    return FixtureModeModel(
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory FixtureModeModel.fromMap(Map<String, dynamic> map) {
    return FixtureModeModel(
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureModeModel.fromJson(String source) =>
      FixtureModeModel.fromMap(json.decode(source));

  @override
  String toString() => 'FixtureModelModel(name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FixtureModeModel && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
