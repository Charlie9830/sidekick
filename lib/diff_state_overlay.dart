import 'package:flutter/material.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class DiffStateOverlay extends StatelessWidget {
  final Widget child;
  final DiffState? diff;
  final bool enabled;
  final bool expand;

  const DiffStateOverlay({
    super.key,
    required this.child,
    required this.diff,
    this.expand = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (diff == null || enabled == false) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(child: Container(color: _getDiffStateColor(diff!)))
      ],
    );
  }

  Color? _getDiffStateColor(DiffState diffState) {
    return switch (diffState) {
      DiffState.unchanged => null,
      DiffState.added => Colors.lightGreenAccent.withAlpha(100),
      DiffState.changed => Colors.orange.withAlpha(100),
      DiffState.deleted => Colors.redAccent.withAlpha(100),
    };
  }
}
