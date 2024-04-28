import 'package:flutter/material.dart';

class BlurListener extends StatelessWidget {
  final Widget child;
  final void Function() onBlur;

  const BlurListener({Key? key, required this.child, required this.onBlur})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus == false) {
          onBlur();
        }
      },
      child: child,
    );
  }
}
