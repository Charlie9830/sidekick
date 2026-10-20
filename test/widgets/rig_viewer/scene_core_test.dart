import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';
import 'package:sidekick/widgets/rig_viewer/scene/picking.dart';
import 'package:sidekick/widgets/rig_viewer/scene/world_space.dart';
import 'package:vector_math/vector_math.dart' as vm;

Matcher _closeToVector(Vector3 expected, [double tolerance = 1e-6]) =>
    isA<Vector3>()
        .having((v) => v.x, 'x', closeTo(expected.x, tolerance))
        .having((v) => v.y, 'y', closeTo(expected.y, tolerance))
        .having((v) => v.z, 'z', closeTo(expected.z, tolerance));

/// Corners in mvr order for a box of the given half-extents about [c].
List<Vector3> _mvrCorners(Vector3 c, double hl, double hw, double hh) => [
  for (final x in [-hl, hl])
    for (final y in [-hw, hw])
      for (final z in [-hh, hh]) c + Vector3(x, y, z),
];

void main() {
  group('WorldSpace', () {
    test('maps mm Z-up to m Y-up', () {
      final scene = WorldSpace.toScene(const Vector3(1000, 2000, 3000));
      expect(scene.x, closeTo(1, 1e-9));
      expect(scene.y, closeTo(3, 1e-9));
      expect(scene.z, closeTo(2, 1e-9));
    });

    test('round trips', () {
      const world = Vector3(-120, 4500, 7800);
      expect(
        WorldSpace.fromScene(WorldSpace.toScene(world)),
        _closeToVector(world, 1e-3),
      );
      expect(
        WorldSpace.directionFromScene(WorldSpace.directionToScene(world)),
        world,
      );
    });
  });

  group('OrientedBox', () {
    test('fromCorners recovers centre, axes and extents', () {
      final box = OrientedBox.fromCorners(
        _mvrCorners(const Vector3(10, 20, 30), 100, 50, 25),
      );

      expect(box.center, _closeToVector(const Vector3(10, 20, 30)));
      expect(box.lengthAxis, _closeToVector(Vector3.unitX));
      expect(box.widthAxis, _closeToVector(Vector3.unitY));
      expect(box.heightAxis, _closeToVector(Vector3.unitZ));
      expect([box.length, box.width, box.height], [200, 100, 50]);
    });

    test('corners round trip through fromCorners', () {
      final corners = _mvrCorners(const Vector3(1, 2, 3), 4, 5, 6);
      final rebuilt = OrientedBox.fromCorners(corners).corners;
      for (var i = 0; i < 8; i++) {
        expect(rebuilt[i], _closeToVector(corners[i]));
      }
    });

    test('transformedBy rotates and places a fixture-local box', () {
      // A quarter turn about Z, placed at (1000, 0, 5000).
      final transform = MVRMatrix([
        [0, 1, 0],
        [-1, 0, 0],
        [0, 0, 1],
        [1000, 0, 5000],
      ]);
      final local = OrientedBox(
        center: const Vector3(100, 0, 0),
        length: 10,
        width: 20,
        height: 30,
      );

      final world = local.transformedBy(transform);

      expect(world.center, _closeToVector(const Vector3(1000, 100, 5000)));
      expect(world.lengthAxis, _closeToVector(Vector3.unitY));
      expect(world.widthAxis, _closeToVector(const Vector3(-1, 0, 0)));
      expect(world.length, 10);
    });

    test('sceneTransform maps the unit cube onto the box', () {
      final box = OrientedBox.fromCorners(
        _mvrCorners(const Vector3(1000, 2000, 3000), 500, 250, 100),
      );
      final transform = box.sceneTransform;

      expect(transform.determinant(), greaterThan(0));

      final sceneCorners = [
        for (final x in [-0.5, 0.5])
          for (final y in [-0.5, 0.5])
            for (final z in [-0.5, 0.5])
              WorldSpace.fromScene(transform.transform3(vm.Vector3(x, y, z))),
      ];
      for (final corner in box.corners) {
        expect(
          sceneCorners.any((c) => c.distanceTo(corner) < 1e-2),
          isTrue,
          reason: '$corner should be a corner of the transformed cube',
        );
      }
    });

    test('sceneTransform runs cylinders along the height axis', () {
      final box = OrientedBox(
        center: Vector3.zero,
        heightAxis: Vector3.unitX,
        lengthAxis: Vector3.unitY,
        widthAxis: Vector3.unitZ,
        length: 100,
        width: 100,
        height: 2000,
      );
      final top = WorldSpace.fromScene(
        box.sceneTransform.transform3(vm.Vector3(0, 0.5, 0)),
      );
      expect(top, _closeToVector(const Vector3(1000, 0, 0), 1e-2));
    });
  });

  group('pick', () {
    final near = OrientedBox.cube(center: const Vector3(0, 0, 1000), size: 100);
    final far = OrientedBox.cube(center: const Vector3(0, 0, 3000), size: 100);
    final targets = <PickTarget>[
      (id: 'far', box: far),
      (id: 'near', box: near),
    ];

    test('returns the nearest box along the ray', () {
      final hit = pick(WorldRay(Vector3.zero, Vector3.unitZ), targets);

      expect(hit?.id, 'near');
      expect(hit?.distance, closeTo(950, 1e-6));
      expect(hit?.point, _closeToVector(const Vector3(0, 0, 950)));
    });

    test('misses boxes beside or behind the ray', () {
      expect(
        pick(WorldRay(const Vector3(500, 0, 0), Vector3.unitZ), targets),
        isNull,
      );
      expect(
        pick(WorldRay(const Vector3(0, 0, 5000), Vector3.unitZ), targets),
        isNull,
      );
    });

    test('hits rotated boxes on their true outline', () {
      // A long thin bar rotated 45° about Z: a ray through its middle hits,
      // one through the corner of its axis-aligned bounds does not.
      const diagonal = Vector3(math.sqrt1_2, math.sqrt1_2, 0);
      final bar = OrientedBox(
        center: Vector3.zero,
        lengthAxis: diagonal,
        widthAxis: const Vector3(-math.sqrt1_2, math.sqrt1_2, 0),
        length: 1000,
        width: 20,
        height: 20,
      );
      final down = Vector3(0, 0, -1);

      expect(
        pick(WorldRay(const Vector3(200, 200, 100), down), [
          (id: 'bar', box: bar),
        ])?.id,
        'bar',
      );
      expect(
        pick(WorldRay(const Vector3(300, -300, 100), down), [
          (id: 'bar', box: bar),
        ]),
        isNull,
      );
    });

    test('a ray starting inside a box hits its exit face', () {
      final hit = pick(WorldRay(const Vector3(0, 0, 1000), Vector3.unitZ), [
        (id: 'near', box: near),
      ]);
      expect(hit?.distance, closeTo(50, 1e-6));
    });
  });
}
