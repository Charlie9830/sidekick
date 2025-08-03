import 'package:flutter/material.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/label_color_model.dart';

class MultiColorChit extends StatelessWidget {
  final LabelColorModel value;
  final double height;
  final bool showPickerIcon;
  const MultiColorChit({
    super.key,
    required this.value,
    this.height = 16,
    this.showPickerIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedColors =
        value.colors.where((color) => color != NamedColors.none).toList();

    return SizedBox(
        height: height,
        width: _computeWidth(sanitizedColors.length, height),
        child:
            (value.colors.isEmpty || value == const LabelColorModel.none()) &&
                    showPickerIcon
                ? const Icon(Icons.color_lens)
                : CustomPaint(
                    painter: ColorPainter(sanitizedColors
                        .map((namedColor) => namedColor.color)
                        .toList()),
                  ));
  }

  double _computeWidth(int colorQty, double height) {
    if (colorQty == 0) {
      return 0;
    }

    if (colorQty <= 2) {
      return height;
    }

    return (height / 1.618) * colorQty;
  }
}

class ColorPainter extends CustomPainter {
  final List<Color> colors;

  ColorPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) {
      return;
    }

    final height = size.height;
    final zoneWidth = size.width / colors.length;

    canvas.clipRRect(RRect.fromLTRBAndCorners(
      size.width,
      size.height,
      0,
      0,
      topLeft: Radius.circular(height),
      bottomLeft: Radius.circular(height),
      topRight: Radius.circular(height),
      bottomRight: Radius.circular(height),
    ));

    for (final (index, color) in colors.indexed) {
      final colorPaint = Paint()..color = color;
      canvas.drawRect(
          Rect.fromLTRB(
              zoneWidth * index, 0, (zoneWidth * index) + zoneWidth, height),
          colorPaint);
    }
  }

  @override
  bool shouldRepaint(ColorPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(ColorPainter oldDelegate) => false;
}
