import 'package:flutter/material.dart';

class CardSubtitle extends StatelessWidget {
  final String text;

  const CardSubtitle(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
