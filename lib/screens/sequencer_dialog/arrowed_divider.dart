import 'package:flutter/material.dart';

class ArrowedDivider extends StatelessWidget {
  const ArrowedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: VerticalDivider()),
        Icon(Icons.arrow_right, size: 72, color: Colors.grey),
        Expanded(child: VerticalDivider()),
      ],
    );
  }
}
