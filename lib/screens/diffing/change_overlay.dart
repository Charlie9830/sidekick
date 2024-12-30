import 'package:flutter/material.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

const int _kAlpha = 50;

class ChangeOverlay extends StatelessWidget {
  final Widget child;
  final ChangeType changeType;

  const ChangeOverlay(
      {super.key, required this.child, required this.changeType});

  @override
  Widget build(BuildContext context) {
    return Container(
      
      foregroundDecoration: BoxDecoration(
        color: switch (changeType) {
          ChangeType.added => const Color.fromARGB(_kAlpha, 0, 255, 0),
          ChangeType.deleted => const Color.fromARGB(_kAlpha, 255, 0, 0),
          ChangeType.modified => const Color.fromARGB(_kAlpha, 255, 255, 0),
          ChangeType.none => Colors.transparent,
        },
      ),
      child: child,
    );
  }
}
