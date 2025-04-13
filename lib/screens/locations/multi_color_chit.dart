import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/locations/color_chit.dart';

class MultiColorChit extends StatelessWidget {
  final LabelColorModel value;
  const MultiColorChit({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      children: value.colors
          .map((namedColor) => ColorChit(
                color: namedColor.color,
              ))
          .toList(),
    );
  }
}
