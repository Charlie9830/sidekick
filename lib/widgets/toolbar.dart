import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  final Widget child;
  final double height;

  const Toolbar({
    Key? key,
    required this.child,
    this.height = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: height,
        child: Card(
          child: child,
        ));
  }
}
