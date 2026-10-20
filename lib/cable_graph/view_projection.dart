import 'dart:ui';

import 'package:sidekick/cable_graph/vector3.dart';

/// Projects a 3D world point (mm, Z-up) into a 2D "diagram" space, e.g. for
/// ordering fixtures by where they appear in a plan view.
///
/// Diagram space keeps millimetre units; the Y axis grows downward to match
/// screen coordinates. The 3D Rig Viewer does not use this; it has its own
/// camera in `widgets/rig_viewer`.
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
