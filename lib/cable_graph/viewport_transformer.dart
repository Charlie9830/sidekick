import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// Handles the translation of physical fixture coordinates (mm) in diagram
/// space into logical screen coordinates (pixels).
///
/// Diagram space is the output of a [ViewProjection] (world → 2D). This fits
/// that space over a set of [BoxConstraints], scaling uniformly and centering,
/// so every point lands inside the viewport. Shared by the cable view and the
/// sequencer plan view.
class ViewportTransformer {
  final double scale;
  final double centeringOffsetX;
  final double centeringOffsetY;
  final double minX;
  final double minY;

  ViewportTransformer._({
    required this.scale,
    required this.centeringOffsetX,
    required this.centeringOffsetY,
    required this.minX,
    required this.minY,
  });

  factory ViewportTransformer.fit({
    required Iterable<Offset> points,
    required BoxConstraints constraints,
    double padding = 240.0,
  }) {
    final xs = points.map((p) => p.dx).toList();
    final ys = points.map((p) => p.dy).toList();
    double minX = xs.minOrNull ?? 0;
    double maxX = xs.maxOrNull ?? 0;
    double minY = ys.minOrNull ?? 0;
    double maxY = ys.maxOrNull ?? 0;

    final mmWidth = maxX - minX;
    final mmHeight = maxY - minY;

    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final drawWidth = max(0.0, screenWidth - (padding * 2));
    final drawHeight = max(0.0, screenHeight - (padding * 2));

    double scale = 1.0;
    if (mmWidth > 0 || mmHeight > 0) {
      final scaleX = mmWidth > 0 ? drawWidth / mmWidth : double.infinity;
      final scaleY = mmHeight > 0 ? drawHeight / mmHeight : double.infinity;
      scale = min(scaleX, scaleY);
      if (scale == double.infinity) scale = 1.0;
    }

    final offsetX = (screenWidth - (mmWidth * scale)) / 2;
    final offsetY = (screenHeight - (mmHeight * scale)) / 2;

    return ViewportTransformer._(
      scale: scale,
      centeringOffsetX: offsetX,
      centeringOffsetY: offsetY,
      minX: minX,
      minY: minY,
    );
  }

  Offset transform(double x, double y) {
    return Offset(
      (x - minX) * scale + centeringOffsetX,
      (y - minY) * scale + centeringOffsetY,
    );
  }
}
