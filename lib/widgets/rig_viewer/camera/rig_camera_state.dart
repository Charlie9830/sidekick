import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vm;

/// Fixed camera angles, matching the old 2D viewer's orthogonal views: each
/// side view is what a viewer standing on that side of the rig sees, and
/// [top] keeps upstage (world +Y) at the top of the screen.
enum RigViewPreset {
  perspective('3D', math.pi + 0.6, 0.45),
  top('Top', math.pi, math.pi / 2),
  bottom('Bottom', 0, -math.pi / 2),
  front('Front', math.pi, 0),
  back('Back', 0, 0),
  left('Left', -math.pi / 2, 0),
  right('Right', math.pi / 2, 0);

  const RigViewPreset(this.label, this.yaw, this.pitch);

  /// Human-readable name for view-switching controls.
  final String label;
  final double yaw;
  final double pitch;
}

/// An immutable camera pose in scene space (metres, Y-up), with the
/// navigation operations of the grandMA3 3D window.
///
/// The camera looks at [target], which always sits at the centre of the view,
/// from [distance] away. [yaw] turns around the vertical axis and [pitch] is
/// the elevation, from -π/2 (looking straight up) to π/2 (straight down).
/// Roll is always zero, so the horizon stays level. Every operation returns a
/// new state, so poses can be compared, animated with [lerp] and tested
/// without a GPU.
class RigCameraState {
  static const double defaultFovY = 45 * vm.degrees2Radians;

  /// Closest the camera may get to its target (m).
  static const double minDistance = 0.05;

  final vm.Vector3 _target;
  final double yaw;
  final double pitch;
  final double distance;

  /// Vertical field of view (radians).
  final double fovY;

  RigCameraState({
    required vm.Vector3 target,
    required this.yaw,
    required double pitch,
    required double distance,
    this.fovY = defaultFovY,
  }) : _target = target.clone(),
       pitch = pitch.clamp(-math.pi / 2, math.pi / 2),
       distance = math.max(distance, minDistance);

  /// A camera at [preset]'s angle looking at the origin from 20 m.
  factory RigCameraState.preset(RigViewPreset preset) => RigCameraState(
    target: vm.Vector3.zero(),
    yaw: preset.yaw,
    pitch: preset.pitch,
    distance: 20,
  );

  /// The point at the centre of the view.
  vm.Vector3 get target => _target.clone();

  /// Unit direction the camera looks along.
  vm.Vector3 get forward => vm.Vector3(
    -math.cos(pitch) * math.sin(yaw),
    -math.sin(pitch),
    -math.cos(pitch) * math.cos(yaw),
  );

  /// Unit direction toward the right edge of the view. Always horizontal, so
  /// it stays defined when looking straight up or down.
  vm.Vector3 get right => vm.Vector3(-math.cos(yaw), 0, math.sin(yaw));

  /// Unit direction toward the top edge of the view.
  ///
  /// flutter_scene is left-handed (`right = up × forward`), hence
  /// `forward × right`.
  vm.Vector3 get up => forward.cross(right)..normalize();

  /// The eye position.
  vm.Vector3 get eye => _target - forward * distance;

  RigCameraState copyWith({
    vm.Vector3? target,
    double? yaw,
    double? pitch,
    double? distance,
  }) => RigCameraState(
    target: target ?? _target,
    yaw: yaw ?? this.yaw,
    pitch: pitch ?? this.pitch,
    distance: distance ?? this.distance,
    fovY: fovY,
  );

  /// Rotate Center: orbits around the point at the centre of the view.
  RigCameraState orbit(double deltaYaw, double deltaPitch) =>
      copyWith(yaw: yaw + deltaYaw, pitch: pitch + deltaPitch);

  /// Rotate Pivot: orbits the whole camera around [pivot], which need not be
  /// at the centre of the view. [pivot] keeps its place on screen.
  RigCameraState orbitAround(
    vm.Vector3 pivot,
    double deltaYaw,
    double deltaPitch,
  ) {
    final next = orbit(deltaYaw, deltaPitch);
    // Rotation taking this camera's frame onto the next one's.
    final rotation = next._frame..multiply(_frame..transpose());
    final eye = pivot + rotation.transformed(this.eye - pivot);
    final target = pivot + rotation.transformed(_target - pivot);

    return RigCameraState(
      target: target,
      yaw: next.yaw,
      pitch: next.pitch,
      distance: eye.distanceTo(target),
      fovY: fovY,
    );
  }

  /// Move: slides the camera in its own plane by a pointer drag of [delta]
  /// pixels, so the content at the target's depth follows the pointer.
  /// Pan and tilt are unchanged.
  RigCameraState move(Offset delta, Size viewSize) {
    final metresPerPixel = 2 * distance * math.tan(fovY / 2) / viewSize.height;
    final shift =
        right * (-delta.dx * metresPerPixel) + up * (delta.dy * metresPerPixel);
    return copyWith(target: _target + shift);
  }

  /// Zoom: moves the camera along the ray through [screenPoint], scaling its
  /// distance by [factor] (below 1 moves closer). The point under the pointer
  /// stays under the pointer, as the scroll wheel does on the console.
  RigCameraState zoomToward(Offset screenPoint, Size viewSize, double factor) {
    final ray = rayThrough(screenPoint, viewSize);
    final eye = this.eye;
    final focus = eye + ray * (distance / ray.dot(forward));
    final nextDistance = math.max(distance * factor, minDistance);
    final nextEye = focus - (focus - eye) * (nextDistance / distance);

    return copyWith(
      target: nextEye + forward * nextDistance,
      distance: nextDistance,
    );
  }

  /// Fit / Fit Selected: centres [bounds] and backs off until they fill the
  /// view, keeping the current angle so the camera never orbits.
  RigCameraState framing(
    vm.Aabb3 bounds,
    Size viewSize, {
    double margin = 1.15,
  }) {
    final radius = math.max((bounds.max - bounds.min).length / 2, 0.5);
    final aspect = viewSize.width / viewSize.height;
    final halfFov = math.min(fovY / 2, math.atan(math.tan(fovY / 2) * aspect));

    return copyWith(
      target: bounds.center,
      distance: radius / math.sin(halfFov) * margin,
    );
  }

  /// This camera turned to [preset]'s angle, keeping target and distance.
  RigCameraState withPreset(RigViewPreset preset) =>
      copyWith(yaw: preset.yaw, pitch: preset.pitch);

  /// Unit direction from [eye] through [screenPoint] (logical pixels, origin
  /// top-left) in a view of [viewSize].
  vm.Vector3 rayThrough(Offset screenPoint, Size viewSize) {
    final tanHalf = math.tan(fovY / 2);
    final ndcX = screenPoint.dx / viewSize.width * 2 - 1;
    final ndcY = 1 - screenPoint.dy / viewSize.height * 2;
    final aspect = viewSize.width / viewSize.height;

    return (forward + right * (ndcX * tanHalf * aspect) + up * (ndcY * tanHalf))
      ..normalize();
  }

  /// Interpolates between two poses for animated camera moves: yaw takes the
  /// short way round and distance scales geometrically, so zooms feel even.
  static RigCameraState lerp(RigCameraState a, RigCameraState b, double t) {
    var deltaYaw = (b.yaw - a.yaw) % (2 * math.pi);
    if (deltaYaw > math.pi) deltaYaw -= 2 * math.pi;

    return RigCameraState(
      target: a._target + (b._target - a._target) * t,
      yaw: a.yaw + deltaYaw * t,
      pitch: a.pitch + (b.pitch - a.pitch) * t,
      distance: a.distance * math.pow(b.distance / a.distance, t),
      fovY: a.fovY + (b.fovY - a.fovY) * t,
    );
  }

  /// The camera's orientation: columns are [right], [up] and [forward].
  vm.Matrix3 get _frame => vm.Matrix3.columns(right, up, forward);

  @override
  String toString() =>
      'RigCameraState(target: $_target, yaw: $yaw, pitch: $pitch, '
      'distance: $distance)';
}
