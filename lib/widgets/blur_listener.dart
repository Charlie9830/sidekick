import 'package:flutter/material.dart';

class BlurListener extends StatelessWidget {
  final Widget child;
  final void Function() onBlur;
  final void Function()? onFocus;

  const BlurListener(
      {Key? key, required this.child, required this.onBlur, this.onFocus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        hasFocus ? onFocus?.call() : onBlur();
      },
      child: child,
    );
  }
}
