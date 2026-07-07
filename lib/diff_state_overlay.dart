import 'package:flutter/material.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

class DiffStateOverlay extends StatelessWidget {
  final Widget child;
  final DiffState? diff;
  final bool enabled;
  final bool expand;

  const DiffStateOverlay({
    super.key,
    required this.diff,
    required this.child,
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
      DiffState.added => SidekickColors.diffAdded.withAlpha(100),
      DiffState.changed => SidekickColors.diffChanged.withAlpha(90),
      DiffState.deleted => SidekickColors.diffDeleted.withAlpha(100),
    };
  }
}
