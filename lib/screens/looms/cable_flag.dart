import 'package:flutter/material.dart';

class CableFlag extends StatelessWidget {
  final Color? color;
  final String text;

  const CableFlag({
    super.key,
    this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
        backgroundColor: color ?? Colors.teal.shade700,
        labelStyle: Theme.of(context).textTheme.labelSmall,
        padding: const EdgeInsets.only(bottom: 4),
        label: Text(text));
  }
}
