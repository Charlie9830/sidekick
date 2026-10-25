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
}) => TrussModel(
  uid: uid,
  center: center,
  lengthAxis: Vector3.unitX,
  widthAxis: Vector3.unitY,
  heightAxis: Vector3.unitZ,
  length: length,
  width: 300,
  height: 300,
);

/// A 4 m vertical truss standing on the floor at [center] (default z 0–4000),
/// [width] along world X and [depth] along world Y.
TrussModel verticalTruss({
  String uid = 'tower',
  Vector3 center = const Vector3(0, 0, 2000),
  double width = 300,
  double depth = 300,
}) => TrussModel(
  uid: uid,
  center: center,
  lengthAxis: Vector3.unitZ,
  widthAxis: Vector3.unitX,
  heightAxis: Vector3.unitY,
  length: 4000,
  width: width,
  height: depth,
);

({String uid, double x, double y, double z}) fixture(
  String uid,
  double x,
  double y,
  double z,
) => (uid: uid, x: x, y: y, z: z);

void main() {
  // Perpendicular distance from a fixture 1000 mm below the truss centre up to
  // the top chord (offset 150 in both width and height).
  final riserToTop = math.sqrt(150 * 150 + 1150 * 1150);

  group('assignment and chord choice', () {
    test('a fixture below the truss is assigned to it', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([fixture('a', 0, 0, -1000)]);

      expect(assignments.containsKey('a'), isTrue);
    });

    test('a fixture beyond the tolerance is left un-trussed', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      // 3 m below — past the 2.5 m assignment tolerance.
      final assignments = geometry.assignFixtures([fixture('a', 0, 0, -3000)]);

      expect(assignments.containsKey('a'), isFalse);
    });

    test('chooses the far (top) chord for fixtures hanging below', () {
      // The riser is measured to the chosen chord; if the near (bottom) chord
      // were picked the riser would be ~863, so a riser near the top chord
      // proves the furthest-chord rule fired.
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([fixture('a', 0, 0, -1000)]);

      expect(assignments['a']!.riser, closeTo(riserToTop, 1));
    });

    test('a fixture inside a horizontal truss uses the top chord above it', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([fixture('a', 0, -100, 0)]);

      // Near top chord (y -150, z 150), not the far one (y 150).
      expect(
        assignments['a']!.riser,
        closeTo(math.sqrt(50 * 50 + 150 * 150), 1),
      );
    });

    test('a fixture atop a horizontal truss uses the nearest top chord', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([fixture('a', 0, 100, 300)]);

      expect(
        assignments['a']!.riser,
        closeTo(math.sqrt(50 * 50 + 150 * 150), 1),
      );
    });

    test('the majority placement on a stick decides its chord', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([
        fixture('a', -1000, -100, 0),
        fixture('b', 1000, -100, 0),
        fixture('c', 0, 0, -1000),
      ]);

      // Two inside, one below: the inside rule picks the near top chord.
      expect(
        assignments['a']!.riser,
        closeTo(math.sqrt(50 * 50 + 150 * 150), 1),
      );
    });

    test('a vertical truss uses its most upstage chord', () {
      final geometry = TrussGeometry.fromTrusses([verticalTruss()]);
      // Hung on the downstage face, so the cable runs down the back.
      final assignments = geometry.assignFixtures([
        fixture('a', 0, -300, 2000),
      ]);

      expect(
        assignments['a']!.riser,
        closeTo(math.sqrt(150 * 150 + 450 * 450), 1),
      );
    });

    test('a vertical ladder ties upstage and falls to the X-negative rail', () {
      final geometry = TrussGeometry.fromTrusses([
        verticalTruss(width: 500, depth: 0),
      ]);
      final assignments = geometry.assignFixtures([fixture('a', 100, 0, 2000)]);

      // Rails at x ±250; the X-negative one is 350 away.
      expect(assignments['a']!.riser, closeTo(350, 1));
    });

    test(
      'a goalpost uses the upstage chord on the leg and top on the header',
      () {
        final geometry = TrussGeometry.fromTrusses([
          verticalTruss(uid: 'leg', center: const Vector3(-2000, 0, 2000)),
          straightTruss(uid: 'header', center: const Vector3(0, 0, 4000)),
        ]);
        final assignments = geometry.assignFixtures([
          fixture('leg', -2000, -300, 2000),
          fixture('header', 0, 0, 3000),
        ]);

        expect(assignments['leg']!.runId, assignments['header']!.runId);
        expect(
          assignments['leg']!.riser,
          closeTo(math.sqrt(150 * 150 + 450 * 450), 1),
        );
        expect(assignments['header']!.riser, closeTo(riserToTop, 1));

        final split = geometry.splitRun(
          from: const Vector3(-2000, -300, 2000),
          to: const Vector3(0, 0, 3000),
          fromAssignment: assignments['leg'],
          toAssignment: assignments['header'],
        );
        expect(split.breakPoints, hasLength(1));
        expect(
          pathLength(split.path),
          closeTo(split.segmentLengths.reduce((a, b) => a + b), 1e-6),
        );
      },
    );
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
      expect(
        split.segmentLengths.single,
        closeTo(riserToTop + 2000 + riserToTop, 1),
      );
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
      final alongX = straightTruss(
        uid: 'x',
        center: const Vector3(-2000, 0, 0),
      );
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
      final assignments = geometry.assignFixtures([
        fixture('a', -1000, 0, -1000),
      ]);

      const header = Vector3(0, 0, -1500);
      final length = geometry.homeRunLength(
        from: header,
        assignment: assignments['a']!,
      );

      // The straight header→fixture distance, which the path must exceed
      // because it detours up to the chord and back down.
      final straight = header.distanceTo(const Vector3(-1000, 0, -1000));
      expect(length, isNotNull);
      expect(length!, greaterThan(straight));
    });

    test('route path matches the length and ends at the fixture', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([
        fixture('a', -1000, 0, -1000),
      ]);
      const header = Vector3(1500, 0, -1500);
      const fixturePoint = Vector3(-1000, 0, -1000);

      final route = geometry.homeRunRoute(
        from: header,
        to: fixturePoint,
        assignment: assignments['a']!,
      )!;

      expect(
        route.length,
        closeTo(
          geometry.homeRunLength(from: header, assignment: assignments['a']!)!,
          1e-6,
        ),
      );
      expect(pathLength(route.path), closeTo(route.length, 1e-6));
      expect(route.path.first, header);
      expect(route.path.last, fixturePoint);
    });
  });

  group('paths', () {
    test('a single-stick link path rises, runs the chord and drops', () {
      final geometry = TrussGeometry.fromTrusses([straightTruss()]);
      final assignments = geometry.assignFixtures([
        fixture('a', -1000, 0, -1000),
        fixture('b', 1000, 0, -1000),
      ]);
      const from = Vector3(-1000, 0, -1000);
      const to = Vector3(1000, 0, -1000);

      final split = geometry.splitRun(
        from: from,
        to: to,
        fromAssignment: assignments['a'],
        toAssignment: assignments['b'],
      );

      final path = split.segmentPaths.single;
      expect(path.first, from);
      expect(path.last, to);
      // Both feet sit on the top chord.
      expect(path[1].z, closeTo(150, 1));
      expect(path[2].z, closeTo(150, 1));
      expect(pathLength(path), closeTo(split.segmentLengths.single, 1e-6));
    });

    test('split segments each match their length and meet at the break', () {
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

      expect(split.segmentPaths, hasLength(2));
      for (var i = 0; i < 2; i++) {
        expect(
          pathLength(split.segmentPaths[i]),
          closeTo(split.segmentLengths[i], 1e-6),
        );
      }
      final breakPoint = split.breakPoints.single;
      expect(split.segmentPaths[0].last.distanceTo(breakPoint), lessThan(1e-6));
      expect(
        split.segmentPaths[1].first.distanceTo(breakPoint),
        lessThan(1e-6),
      );
      expect(
        pathLength(split.path),
        closeTo(split.segmentLengths.reduce((a, b) => a + b), 1e-6),
      );
    });

    test('a link around a corner follows the corner', () {
      final alongX = straightTruss(
        uid: 'x',
        center: const Vector3(-2000, 0, 0),
      );
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

      expect(
        pathLength(split.path),
        closeTo(split.segmentLengths.reduce((a, b) => a + b), 1e-6),
      );
    });

    test('a floor link runs level between its two ends', () {
      final geometry = TrussGeometry.fromTrusses(const []);
      const from = Vector3(0, 0, 0);
      const to = Vector3(3000, 0, 0);

      final split = geometry.splitRun(
        from: from,
        to: to,
        fromAssignment: null,
        toAssignment: null,
      );

      expect(split.path, [from, to]);
    });
  });
}
