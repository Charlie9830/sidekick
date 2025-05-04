import 'package:flutter/material.dart';

SnackBar importSuccessSnackBar(BuildContext context) {
  return SnackBar(
    backgroundColor: Colors.green,
    content: Row(
      children: [
        const Icon(
          Icons.thumb_up,
        ),
        const SizedBox(width: 16),
        Text('Patch Imported!', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
