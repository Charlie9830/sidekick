import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/cable_graph/view_projection.dart';

void main() {
  group('PlanProjection', () {
    const projection = PlanProjection();

    test('maps world (x, y) to (x, -y) and discards height', () {
      expect(projection.project(100, 250, 999), const Offset(100, -250));
    });

    test('projectVector agrees with project', () {
      const v = Vector3(12, -34, 56);
      expect(projection.projectVector(v), projection.project(v.x, v.y, v.z));
    });

    test('a fixture and a truss centred on it project to the same point', () {
      // Guards the "trusses drawn too far left" regression: fixtures and truss
      // geometry must share one projection, so a truss centred on a fixture
      // lands exactly on it — no divergent Y-flip or offset.
      const fixture = Vector3(5000, -2000, 3000);
      expect(projection.projectVector(fixture),
          projection.project(5000, -2000, 8000));
    });
  });

  group('convexHull', () {
    test('returns the four corners of an axis-aligned square', () {
      final hull = convexHull(const [
        Offset(0, 0),
        Offset(2, 0),
        Offset(2, 2),
        Offset(0, 2),
        Offset(1, 1), // interior point is dropped
      ]);
      expect(hull.length, 4);
      expect(hull.toSet(), {
        const Offset(0, 0),
        const Offset(2, 0),
        const Offset(2, 2),
        const Offset(0, 2),
      });
    });

    test('collapses a projected box (8 corners) to a 4-point footprint', () {
      // Eight corners of a 2 x 2 x 10 box: the two Z layers coincide in plan.
      final corners = <Offset>[
        for (final x in const [0.0, 2.0])
          for (final y in const [0.0, 2.0])
            for (final _ in const [0.0, 10.0]) Offset(x, y),
      ];
      expect(convexHull(corners).length, 4);
    });

    test('returns points unchanged when fewer than three', () {
      expect(convexHull(const [Offset(1, 1)]).length, 1);
      expect(convexHull(const [Offset(1, 1), Offset(2, 2)]).length, 2);
    });
  });
}
