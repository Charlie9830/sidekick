import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/truss_geometry.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/truss_model.dart';

/// A straight truss along world X, centred on [center], 4 m long, 0.3 m square.
TrussModel straightTruss({
  String uid = 'truss',
  Vector3 center = Vector3.zero,
  double length = 4000,
}) =>
    TrussModel(
      uid: uid,
      center: center,
      lengthAxis: Vector3.unitX,
      widthAxis: Vector3.unitY,
      heightAxis: Vector3.unitZ,
      length: length,
      width: 300,
      height: 300,
    );

({String uid, double x, double y, double z}) fixture(
        String uid, double x, double y, double z) =>
    (uid: uid, x: x, y: y, z: z);

void main() {
  // Perpendicular distance from a fixture 1000 mm below the truss centre up to
  // the top chord (offset 150 in both width and height).
  final riserToTop = math.sqrt(150 * 150 + 1150 * 1150);

  group('assignment and chord choice', () {
    test('a fixture below the truss is assigned to it', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments =
          geometry.assignFixtures([fixture('a', 0, 0, -1000)]);

      expect(assignments.containsKey('a'), isTrue);
    });

    test('a fixture beyond the tolerance is left un-trussed', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      // 3 m below — past the 2.5 m assignment tolerance.
      final assignments =
          geometry.assignFixtures([fixture('a', 0, 0, -3000)]);

      expect(assignments.containsKey('a'), isFalse);
    });

    test('chooses the far (top) chord for fixtures hanging below', () {
      // The riser is measured to the chosen chord; if the near (bottom) chord
      // were picked the riser would be ~863, so a riser near the top chord
      // proves the furthest-chord rule fired.
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments =
          geometry.assignFixtures([fixture('a', 0, 0, -1000)]);

      expect(assignments['a']!.riser, closeTo(riserToTop, 1));
    });
  });

  group('link runs', () {
    test('single stick: riser + along + riser, no breaks', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([
        fixture('a', -1000, 0, -1000),
        fixture('b', 1000, 0, -1000),
      ]);

      final split = geometry.splitRun(
        from: const Vector3(-1000, 0, -1000),
        to: const Vector3(1000, 0, -1000),
        fromAssignment: assignments['a'],
        toAssignment: assignments['b'],
      );

      expect(split.hasBreaks, isFalse);
      expect(split.segmentLengths.single,
          closeTo(riserToTop + 2000 + riserToTop, 1));
    });

    test('breaks at the join between two in-line sticks', () {
      final geometry = TrussGeometry.fromTrusses([
        straightTruss(uid: 't1', center: const Vector3(-2000, 0, 0)),
        straightTruss(uid: 't2', center: const Vector3(2000, 0, 0)),
      ]);
      final assignments = geometry.assignFixtures([
        fixture('a', -3000, 0, -1000),
        fixture('b', 3000, 0, -1000),
      ]);

      final split = geometry.splitRun(
        from: const Vector3(-3000, 0, -1000),
        to: const Vector3(3000, 0, -1000),
        fromAssignment: assignments['a'],
        toAssignment: assignments['b'],
      );

      expect(split.breakPoints.length, 1);
      expect(split.segmentLengths.length, 2);
      // The join sits at x = 0 on the top chord.
      expect(split.breakPoints.single.x, closeTo(0, 1));
      expect(split.breakPoints.single.z, closeTo(150, 1));
      // Total run length is conserved across the two segments.
      final total = split.segmentLengths.reduce((a, b) => a + b);
      expect(total, closeTo(riserToTop + 6000 + riserToTop, 1));
    });

    test('routes a link around a corner, breaking at the corner join', () {
      final alongX = straightTruss(uid: 'x', center: const Vector3(-2000, 0, 0));
      final alongY = TrussModel(
        uid: 'y',
        center: const Vector3(0, 2000, 0),
        lengthAxis: Vector3.unitY,
        widthAxis: const Vector3(-1, 0, 0),
        heightAxis: Vector3.unitZ,
        length: 4000,
        width: 300,
        height: 300,
      );
      final geometry = TrussGeometry.fromTrusses([alongX, alongY]);
      final assignments = geometry.assignFixtures([
        fixture('a', -3000, 0, -1000),
        fixture('b', 0, 3000, -1000),
      ]);

      final split = geometry.splitRun(
        from: const Vector3(-3000, 0, -1000),
        to: const Vector3(0, 3000, -1000),
        fromAssignment: assignments['a'],
        toAssignment: assignments['b'],
      );

      expect(split.breakPoints.length, 1);
      expect(split.segmentLengths.length, 2);
    });
  });

  group('floor fixtures', () {
    test('un-trussed link is 500 + horizontal + 500', () {
      final geometry = TrussGeometry.fromTrusses(const []);
      expect(geometry.isEmpty, isTrue);

      final split = geometry.splitRun(
        from: const Vector3(0, 0, 0),
        to: const Vector3(3000, 0, 0),
        fromAssignment: null,
        toAssignment: null,
      );

      expect(split.hasBreaks, isFalse);
      expect(split.segmentLengths.single, closeTo(500 + 3000 + 500, 1e-6));
    });
  });

  group('home runs', () {
    test('follows the chord instead of cutting straight to the fixture', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments =
          geometry.assignFixtures([fixture('a', -1000, 0, -1000)]);

      const header = Vector3(0, 0, -1500);
      final length =
          geometry.homeRunLength(from: header, assignment: assignments['a']!);

      // The straight header→fixture distance, which the path must exceed
      // because it detours up to the chord and back down.
      final straight = header.distanceTo(const Vector3(-1000, 0, -1000));
      expect(length, isNotNull);
      expect(length!, greaterThan(straight));
    });
  });
}
