import 'package:mvr/mvr.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/widgets/rig_viewer/scene/world_space.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A box in world space (mm, Z-up): a centre, three orthogonal unit axes and
/// the box's full extent along each.
///
/// Every solid in the rig (fixture parts, truss sticks, connectors) is drawn
/// and picked as one of these, so the scene only ever needs a unit cube or
/// cylinder scaled into place by [sceneTransform].
class OrientedBox {
  final Vector3 center;

  /// Unit axes. [heightAxis] is the axis a cylinder runs along.
  final Vector3 lengthAxis;
  final Vector3 widthAxis;
  final Vector3 heightAxis;

  /// Full extents (mm) along [lengthAxis], [widthAxis] and [heightAxis].
  final double length;
  final double width;
  final double height;

  const OrientedBox({
    required this.center,
    this.lengthAxis = Vector3.unitX,
    this.widthAxis = Vector3.unitY,
    this.heightAxis = Vector3.unitZ,
    required this.length,
    required this.width,
    required this.height,
  });

  /// An axis-aligned cube of [size] mm centred on [center].
  const OrientedBox.cube({required this.center, required double size})
    : lengthAxis = Vector3.unitX,
      widthAxis = Vector3.unitY,
      heightAxis = Vector3.unitZ,
      length = size,
      width = size,
      height = size;

  /// Rebuilds a box from its eight [corners], ordered as the mvr package
  /// emits them: corner `i` sits at `(±length, ±width, ±height)` with the
  /// signs taken from bits 2, 1 and 0 of `i` (clear = negative).
  ///
  /// Degenerate edges (a flat part) keep a sensible axis via
  /// [Vector3.normalized], so the result is always drawable.
  factory OrientedBox.fromCorners(List<Vector3> corners) {
    assert(corners.length == 8, 'An oriented box needs eight corners');
    final origin = corners[0];
    final lengthEdge = corners[4] - origin;
    final widthEdge = corners[2] - origin;
    final heightEdge = corners[1] - origin;

    return OrientedBox(
      center: (origin + corners[7]) * 0.5,
      lengthAxis: lengthEdge.normalized,
      widthAxis: widthEdge.normalized,
      heightAxis: heightEdge.normalized,
      length: lengthEdge.length,
      width: widthEdge.length,
      height: heightEdge.length,
    );
  }

  /// The box occupied by [truss].
  factory OrientedBox.fromTruss(TrussModel truss) => OrientedBox(
    center: truss.center,
    lengthAxis: truss.lengthAxis,
    widthAxis: truss.widthAxis,
    heightAxis: truss.heightAxis,
    length: truss.length,
    width: truss.width,
    height: truss.height,
  );

  /// This box carried from a fixture's local space into world space by the
  /// fixture's [transform].
  OrientedBox transformedBy(MVRMatrix transform) {
    Vector3 point(Vector3 local) {
      final world = transform.transform(MVRVector3(local.x, local.y, local.z));
      return Vector3(world.x, world.y, world.z);
    }

    Vector3 direction(Vector3 local) {
      final world = transform.transformDirection(
        MVRVector3(local.x, local.y, local.z),
      );
      return Vector3(world.x, world.y, world.z).normalized;
    }

    return OrientedBox(
      center: point(center),
      lengthAxis: direction(lengthAxis),
      widthAxis: direction(widthAxis),
      heightAxis: direction(heightAxis),
      length: length,
      width: width,
      height: height,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrientedBox &&
      other.center == center &&
      other.lengthAxis == lengthAxis &&
      other.widthAxis == widthAxis &&
      other.heightAxis == heightAxis &&
      other.length == length &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(
    center,
    lengthAxis,
    widthAxis,
    heightAxis,
    length,
    width,
    height,
  );

  /// The box's eight corners in world space, in [OrientedBox.fromCorners]
  /// order.
  List<Vector3> get corners => [
    for (final l in const [-0.5, 0.5])
      for (final w in const [-0.5, 0.5])
        for (final h in const [-0.5, 0.5])
          center +
              lengthAxis * (l * length) +
              widthAxis * (w * width) +
              heightAxis * (h * height),
  ];

  /// The scene-space transform that maps flutter_scene's unit primitives
  /// (centred on the origin, extent 1, cylinders along local Y) onto this
  /// box.
  ///
  /// Local X takes [lengthAxis], local Y [heightAxis] and local Z
  /// [widthAxis]. The world-to-scene axis swap is a reflection, which would
  /// turn the primitives inside out under back-face culling, so the Z column
  /// is negated whenever the determinant comes out negative. Unit cubes and
  /// capped cylinders are symmetric, so the flip is invisible.
  vm.Matrix4 get sceneTransform {
    final x =
        WorldSpace.directionToScene(lengthAxis) *
        (length / kMillimetresPerSceneUnit);
    final y =
        WorldSpace.directionToScene(heightAxis) *
        (height / kMillimetresPerSceneUnit);
    var z =
        WorldSpace.directionToScene(widthAxis) *
        (width / kMillimetresPerSceneUnit);
    if (x.cross(y).dot(z) < 0) {
      z = -z;
    }
    final t = WorldSpace.toScene(center);

    return vm.Matrix4(
      x.x,
      x.y,
      x.z,
      0, //
      y.x,
      y.y,
      y.z,
      0, //
      z.x,
      z.y,
      z.z,
      0, //
      t.x,
      t.y,
      t.z,
      1, //
    );
  }
}
