import 'package:flutter/material.dart';

enum DiffState {
  unchanged,
  added,
  changed,
  deleted,
}

class DiffStateOverlay extends StatelessWidget {
  final Widget child;
  final DiffState diff;
  final bool expand;
  final bool enabled;

  const DiffStateOverlay(
      {super.key,
      required this.child,
      required this.diff,
      this.expand = true,
      this.enabled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      foregroundDecoration: BoxDecoration(
        color: enabled ? _getDiffStateColor(diff) : null,
      ),
      child: expand ? SizedBox.expand(child: child) : child,
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


