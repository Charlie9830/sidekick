import 'package:flutter/material.dart';

SnackBar compositionRepairSnackBar(BuildContext context, String message) {
  return SnackBar(
    backgroundColor: Colors.yellow[900],
    content: Row(
      children: [
        const Icon(Icons.sentiment_dissatisfied, color: Colors.black),
        const SizedBox(width: 8),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Colors.black)),
      ],
    ),
  );
}
