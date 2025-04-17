// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/named_color_model.dart';

class LabelColorModel {
  final List<NamedColorModel> colors;

  LabelColorModel({
    required this.colors,
  });

  const LabelColorModel.none()
      : colors = const [
          NamedColors.none,
        ];

  factory LabelColorModel.combine(List<LabelColorModel> others) {
    return LabelColorModel(
        colors: others.map((item) => item.colors).flattened.toList());
  }

  String get name => colors.map((color) => color.name).join('/');

  LabelColorModel copyWith({
    List<NamedColorModel>? colors,
  }) {
    return LabelColorModel(
      colors: colors ?? this.colors,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'colors': colors.map((x) => x.toMap()).toList(),
    };
  }

  factory LabelColorModel.fromMap(Map<String, dynamic> map) {
    return LabelColorModel(
      colors: List<NamedColorModel>.from(
        (map['colors'] as List<dynamic>).map<NamedColorModel>(
          (x) => NamedColorModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory LabelColorModel.fromJson(String source) =>
      LabelColorModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
