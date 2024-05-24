import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  final Widget child;
  
  const Toolbar({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 64,
        child: Card(
          child: child,
        ));
  }
}
