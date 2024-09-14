import 'package:flutter/material.dart';

SnackBar fileSaveSuccessSnackBar() {
  return const SnackBar(
    content: Row(
      children: [
        Icon(Icons.thumb_up),
        SizedBox(width: 8),
        Text('File Saved.'),
      ],
    ),
  );
}
