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
    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
          color: color ?? Colors.teal.shade700,
          borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(text,
          style:
              Theme.of(context).textTheme.labelSmall!.copyWith(fontSize: 10)),
    );
  }
}
