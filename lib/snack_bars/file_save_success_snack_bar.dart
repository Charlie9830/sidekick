import 'package:flutter/material.dart';

SnackBar fileSaveSuccessSnackBar(BuildContext context) {
  return SnackBar(
    backgroundColor: Colors.green,
    content: Row(
      children: [
        const Icon(Icons.thumb_up,),
        const SizedBox(width: 16),
        Text('File Saved', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
