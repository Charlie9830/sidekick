import 'package:flutter/material.dart';

class IconLabel extends StatelessWidget {
  final Icon icon;
  final String label;
  final TextStyle? style;

  const IconLabel({
    required this.icon,
    required this.label,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      icon,
      const SizedBox(width: 4),
      Text(
        label,
        style: style,
      ),
    ]);
  }
}
