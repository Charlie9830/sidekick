import 'package:sidekick/cable_graph/vector3.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Millimetres of world space in one scene unit (a metre).
const double kMillimetresPerSceneUnit = 1000;

/// The one place world space meets scene space.
///
/// World space is the imported MVR convention used everywhere else in the
/// app: millimetres, Z-up, right-handed. Scene space is what flutter_scene
/// renders: metres, Y-up, left-handed. Swapping Y and Z both lifts Z to up and
/// flips handedness, so the conversion is a swap plus a scale. Keeping it in
/// one place avoids the scattered-flip bugs the 2D viewer once had.
abstract final class WorldSpace {
  /// Converts a world point (mm) into scene space (m).
  static vm.Vector3 toScene(Vector3 world) => vm.Vector3(
    world.x / kMillimetresPerSceneUnit,
    world.z / kMillimetresPerSceneUnit,
    world.y / kMillimetresPerSceneUnit,
  );

  /// Converts a scene point (m) back into world space (mm).
  static Vector3 fromScene(vm.Vector3 scene) => Vector3(
    scene.x * kMillimetresPerSceneUnit,
    scene.z * kMillimetresPerSceneUnit,
    scene.y * kMillimetresPerSceneUnit,
  );

  /// Converts a world direction into scene space without scaling, so unit
  /// vectors stay unit length.
  static vm.Vector3 directionToScene(Vector3 world) =>
      vm.Vector3(world.x, world.z, world.y);

  /// Converts a scene direction back into world space without scaling.
  static Vector3 directionFromScene(vm.Vector3 scene) =>
      Vector3(scene.x, scene.z, scene.y);
}
