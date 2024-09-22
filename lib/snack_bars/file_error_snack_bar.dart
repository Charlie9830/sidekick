import 'package:flutter/material.dart';

SnackBar fileErrorSnackBar(BuildContext context, String message) {
  return SnackBar(
    backgroundColor: Colors.red.shade900,
    content: Row(
      children: [
        const Icon(Icons.sentiment_dissatisfied, color: Colors.white),
        const SizedBox(width: 8),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Colors.white)),
      ],
    ),
  );
}
