import 'package:flutter/material.dart';

class DiffItem extends StatelessWidget {
  final Widget original;
  final Widget current;

  const DiffItem({
    super.key,
    required this.original,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: original),
        const SizedBox(width: 24),
        Expanded(child: current),
      ],
    );
  }
}
