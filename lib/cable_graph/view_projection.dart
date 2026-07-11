import 'dart:ui';

import 'package:sidekick/cable_graph/vector3.dart';

/// Projects a 3D world point (mm, Z-up) into the 2D "diagram" space used by the
/// cable view, before the viewport fit scales it to screen pixels.
///
/// This is the single place the choice of viewpoint lives. Swapping one
/// [OrthogonalView] for another re-orients the whole rig view without touching
/// any element, edge or truss code. Diagram space keeps millimetre units; the
/// Y axis grows downward to match screen coordinates.
abstract class ViewProjection {
  const ViewProjection();

  /// Maps a world point to diagram space.
  Offset project(double x, double y, double z);

  /// Maps a world [Vector3] to diagram space.
  Offset projectVector(Vector3 v) => project(v.x, v.y, v.z);
}

/// The six axis-aligned viewpoints of the rig, each usable directly as a
/// [ViewProjection].
///
/// Each mapping is what a viewer on the named side of the rig sees looking
/// toward it: [top] keeps world +Y up the page (a standard plan), the four
/// side views keep world +Z (height) up the page, and opposite views mirror
/// each other horizontally — as physically viewing the rig from the other
/// side would. Diagram Y grows downward, hence the negated vertical axis.
enum OrthogonalView implements ViewProjection {
  top('Top'),
  bottom('Bottom'),
  front('Front'),
  back('Back'),
  left('Left'),
  right('Right');

  const OrthogonalView(this.label);

  /// Human-readable name shown by view-switching controls.
  final String label;

  @override
  Offset project(double x, double y, double z) => switch (this) {
    top => Offset(x, -y),
    bottom => Offset(-x, -y),
    front => Offset(x, -z),
    back => Offset(-x, -z),
    left => Offset(-y, -z),
    right => Offset(y, -z),
  };

  @override
  Offset projectVector(Vector3 v) => project(v.x, v.y, v.z);
}

/// Returns the convex hull of [points] as an ordered polygon (Andrew's monotone
/// chain). Fewer than three points are returned unchanged.
///
/// Used to draw a truss footprint: its eight projected corners collapse to a
/// 4–6 sided outline that is correct for any orientation, including raked or
/// rolled trusses whose footprint is not axis-aligned.
List<Offset> convexHull(List<Offset> points) {
  if (points.length <= 2) return List.of(points);

  final sorted = [
    ...points,
  ]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));

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
