import 'package:flutter/material.dart';

class ColorChit extends StatelessWidget {
  final Color color;

  const ColorChit({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (color.alpha == 0) {
      return const Icon(Icons.palette, size: 16, color: Colors.grey);
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
