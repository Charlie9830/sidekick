import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';

/// Paints the projected footprint of a fixture's GDTF parts, giving fixtures
/// their real physical outline instead of a placeholder square.
///
/// [hulls] and [bounds] are produced by [projectedPartHulls] /
/// [projectedHullBounds]: diagram-space millimetres relative to the fixture's
/// origin. The painter only rescales them into its own [Size], which the
/// caller derives from the same bounds, so parts keep their true proportions.
class FixtureGeometryPainter extends CustomPainter {
  final List<List<Offset>> hulls;
  final Rect bounds;
  final Color fillColor;
  final Color strokeColor;

  FixtureGeometryPainter({
    required this.hulls,
    required this.bounds,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bounds.width <= 0 || bounds.height <= 0) {
      return;
    }

    final scale = size.width / bounds.width;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final hull in hulls) {
      if (hull.length < 3) {
        continue;
      }

      final path = Path();
      final start = (hull.first - bounds.topLeft) * scale;
      path.moveTo(start.dx, start.dy);
      for (final point in hull.skip(1)) {
        final p = (point - bounds.topLeft) * scale;
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FixtureGeometryPainter oldDelegate) {
    return oldDelegate.hulls != hulls ||
        oldDelegate.bounds != bounds ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

/// Projects each part of [geometry] into diagram space and reduces it to its
/// outline, all relative to the fixture's origin (mm).
///
/// The fixture's yaw ([rotationZDegrees]) is applied to the 3D corners before
/// projection so plan footprints orient with the fixture. Rake and roll are
/// not applied yet; the stored corners are full 3D points, so other
/// orthogonal [ViewProjection]s (front, side) work by swapping [projection].
List<List<Offset>> projectedPartHulls(
  FixtureGeometryModel geometry,
  double rotationZDegrees,
  ViewProjection projection,
) {
  final radians = rotationZDegrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  return [
    for (final part in geometry.parts)
      convexHull([
        for (final corner in part.corners)
          projection.project(
            corner.x * cos - corner.y * sin,
            corner.x * sin + corner.y * cos,
            corner.z,
          ),
      ]),
  ];
}

/// The axis-aligned bounds enclosing every point of [hulls], or null when the
/// hulls are empty or degenerate (no usable footprint).
Rect? projectedHullBounds(List<List<Offset>> hulls) {
  double? minX, minY, maxX, maxY;

  for (final hull in hulls) {
    for (final point in hull) {
      minX = minX == null ? point.dx : math.min(minX, point.dx);
      maxX = maxX == null ? point.dx : math.max(maxX, point.dx);
      minY = minY == null ? point.dy : math.min(minY, point.dy);
      maxY = maxY == null ? point.dy : math.max(maxY, point.dy);
    }
  }

  if (minX == null || minY == null || maxX == null || maxY == null) {
    return null;
  }

  final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
  return rect.width <= 0 || rect.height <= 0 ? null : rect;
}
