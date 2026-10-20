import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';

/// A ray in world space (mm), e.g. from the camera through the pointer.
class WorldRay {
  final Vector3 origin;

  /// Unit direction.
  final Vector3 direction;

  WorldRay(this.origin, Vector3 direction) : direction = direction.normalized;

  Vector3 at(double distance) => origin + direction * distance;
}

/// A pickable solid: one box belonging to the item identified by [id] (a
/// fixture uid). An item made of several parts contributes several targets.
typedef PickTarget = ({String id, OrientedBox box});

/// The nearest solid a [WorldRay] hit.
class PickHit {
  final String id;

  /// Where the ray entered the box (world mm), used to set the orbit pivot.
  final Vector3 point;

  /// Distance (mm) along the ray to [point].
  final double distance;

  const PickHit({
    required this.id,
    required this.point,
    required this.distance,
  });
}

/// Returns the nearest of [targets] that [ray] hits in front of its origin,
/// or null when it misses them all.
PickHit? pick(WorldRay ray, Iterable<PickTarget> targets) {
  PickHit? nearest;
  for (final target in targets) {
    final distance = _intersect(ray, target.box);
    if (distance != null && (nearest == null || distance < nearest.distance)) {
      nearest = PickHit(
        id: target.id,
        point: ray.at(distance),
        distance: distance,
      );
    }
  }
  return nearest;
}

/// Slab test in the box's own frame. Returns the entry distance, or the exit
/// distance when the ray starts inside the box, or null on a miss.
double? _intersect(WorldRay ray, OrientedBox box) {
  final offset = box.center - ray.origin;
  var near = double.negativeInfinity;
  var far = double.infinity;

  for (final (axis, extent) in [
    (box.lengthAxis, box.length),
    (box.widthAxis, box.width),
    (box.heightAxis, box.height),
  ]) {
    final half = extent / 2;
    final e = axis.dot(offset);
    final f = axis.dot(ray.direction);

    if (f.abs() < 1e-9) {
      // Parallel to this slab: a miss unless the origin lies between its faces.
      if (-e - half > 0 || -e + half < 0) return null;
      continue;
    }

    var t1 = (e + half) / f;
    var t2 = (e - half) / f;
    if (t1 > t2) (t1, t2) = (t2, t1);
    if (t1 > near) near = t1;
    if (t2 < far) far = t2;
    if (near > far || far < 0) return null;
  }

  return near >= 0 ? near : far;
}
