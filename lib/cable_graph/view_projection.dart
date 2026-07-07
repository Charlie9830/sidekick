import 'dart:ui';

import 'package:sidekick/cable_graph/vector3.dart';

/// Projects a 3D world point (mm, Z-up) into the 2D "diagram" space used by the
/// cable view, before the viewport fit scales it to screen pixels.
///
/// This is the single place the choice of viewpoint lives. Swapping
/// [PlanProjection] for a front or side projection re-orients the whole cable
/// view without touching any element, edge or truss code. Diagram space keeps
/// millimetre units; the Y axis grows downward to match screen coordinates.
abstract class ViewProjection {
  const ViewProjection();

  /// Maps a world point to diagram space.
  Offset project(double x, double y, double z);

  /// Maps a world [Vector3] to diagram space.
  Offset projectVector(Vector3 v) => project(v.x, v.y, v.z);
}

/// Top-down plan view: world X → right, world Y → up the page (hence negated so
/// diagram Y grows downward), world Z (height) discarded.
class PlanProjection extends ViewProjection {
  const PlanProjection();

  @override
  Offset project(double x, double y, double z) => Offset(x, -y);
}

/// Returns the convex hull of [points] as an ordered polygon (Andrew's monotone
/// chain). Fewer than three points are returned unchanged.
///
/// Used to draw a truss footprint: its eight projected corners collapse to a
/// 4–6 sided outline that is correct for any orientation, including raked or
/// rolled trusses whose footprint is not axis-aligned.
List<Offset> convexHull(List<Offset> points) {
  if (points.length <= 2) return List.of(points);

  final sorted = [...points]
    ..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));

  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

  final lower = <Offset>[];
  for (final p in sorted) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  final upper = <Offset>[];
  for (final p in sorted.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}
