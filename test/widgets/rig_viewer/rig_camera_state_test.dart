import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera_state.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _view = Size(800, 600);

/// Where flutter_scene itself would draw [point] for [state].
Offset _screen(RigCameraState state, vm.Vector3 point) =>
    rigCamera(state).worldToScreen(point, _view)!;

Matcher _closeToOffset(Offset expected) => isA<Offset>()
    .having((o) => o.dx, 'dx', closeTo(expected.dx, 1e-2))
    .having((o) => o.dy, 'dy', closeTo(expected.dy, 1e-2));

Matcher _closeToVector(vm.Vector3 expected) => isA<vm.Vector3>()
    .having((v) => v.x, 'x', closeTo(expected.x, 1e-4))
    .having((v) => v.y, 'y', closeTo(expected.y, 1e-4))
    .having((v) => v.z, 'z', closeTo(expected.z, 1e-4));

void main() {
  final pose = RigCameraState(
    target: vm.Vector3(1, 2, 3),
    yaw: 0.7,
    pitch: 0.4,
    distance: 12,
  );

  group('basis', () {
    test('target sits at the centre of the view', () {
      expect(
        _screen(pose, pose.target),
        _closeToOffset(const Offset(400, 300)),
      );
    });

    test('right and up point to the right and top of the screen', () {
      final centre = _screen(pose, pose.target);
      final toRight = _screen(pose, pose.target + pose.right);
      final toUp = _screen(pose, pose.target + pose.up);

      expect(toRight.dx, greaterThan(centre.dx));
      expect(toRight.dy, closeTo(centre.dy, 1e-2));
      expect(toUp.dy, lessThan(centre.dy));
      expect(toUp.dx, closeTo(centre.dx, 1e-2));
    });

    test('rayThrough agrees with flutter_scene projection', () {
      const pixel = Offset(130, 470);
      final point = pose.eye + pose.rayThrough(pixel, _view) * 7;

      expect(_screen(pose, point), _closeToOffset(pixel));
    });
  });

  group('presets', () {
    // World +X is scene +X and world +Y (upstage) is scene +Z.
    final stageRight = vm.Vector3(1, 0, 0);
    final upstage = vm.Vector3(0, 0, 1);
    final up = vm.Vector3(0, 1, 0);

    RigCameraState at(RigViewPreset preset) => RigCameraState.preset(preset);

    test('top is a plan: +X right, upstage at the top', () {
      final camera = at(RigViewPreset.top);
      expect(camera.right, _closeToVector(stageRight));
      expect(camera.up, _closeToVector(upstage));
    });

    test('front looks upstage with +X right and height up', () {
      final camera = at(RigViewPreset.front);
      expect(camera.forward, _closeToVector(upstage));
      expect(camera.right, _closeToVector(stageRight));
      expect(camera.up, _closeToVector(up));
    });

    test('opposite views mirror each other', () {
      expect(
        at(RigViewPreset.back).right,
        _closeToVector(-at(RigViewPreset.front).right),
      );
      expect(
        at(RigViewPreset.right).right,
        _closeToVector(-at(RigViewPreset.left).right),
      );
      expect(
        at(RigViewPreset.bottom).right,
        _closeToVector(-at(RigViewPreset.top).right),
      );
    });

    test('top renders through flutter_scene without degenerating', () {
      final camera = at(RigViewPreset.top);
      expect(
        _screen(camera, camera.target),
        _closeToOffset(const Offset(400, 300)),
      );
    });
  });

  group('navigation', () {
    test('orbit keeps the target and distance', () {
      final next = pose.orbit(0.3, -0.2);

      expect(next.target, _closeToVector(pose.target));
      expect(next.distance, closeTo(pose.distance, 1e-9));
      expect(next.yaw, closeTo(pose.yaw + 0.3, 1e-9));
      expect(next.pitch, closeTo(pose.pitch - 0.2, 1e-9));
    });

    test('pitch clamps at straight up and straight down', () {
      expect(pose.orbit(0, 10).pitch, math.pi / 2);
      expect(pose.orbit(0, -10).pitch, -math.pi / 2);
    });

    test('orbitAround keeps the pivot fixed on screen', () {
      final pivot = vm.Vector3(4, 1, -2);
      final before = _screen(pose, pivot);
      final next = pose.orbitAround(pivot, 0.5, 0.3);

      expect(_screen(next, pivot), _closeToOffset(before));
      expect(next.yaw, closeTo(pose.yaw + 0.5, 1e-6));
      expect(next.pitch, closeTo(pose.pitch + 0.3, 1e-6));
    });

    test('move drags the target-depth content with the pointer', () {
      const delta = Offset(40, -25);
      final next = pose.move(delta, _view);

      expect(
        _screen(next, pose.target),
        _closeToOffset(const Offset(400, 300) + delta),
      );
      expect(next.yaw, pose.yaw);
      expect(next.pitch, pose.pitch);
    });

    test('zoomToward keeps the point under the pointer', () {
      const pointer = Offset(620, 140);
      final ray = pose.rayThrough(pointer, _view);
      final focus = pose.eye + ray * (pose.distance / ray.dot(pose.forward));

      final next = pose.zoomToward(pointer, _view, 0.5);

      expect(next.distance, closeTo(pose.distance * 0.5, 1e-9));
      expect(_screen(next, focus), _closeToOffset(pointer));
    });

    test('zoomTowardPoint keeps a point off the target plane in place', () {
      // Something well behind the target, under an off-centre pixel.
      const pointer = Offset(150, 420);
      final focus = pose.eye + pose.rayThrough(pointer, _view) * 30;

      final next = pose.zoomTowardPoint(focus, 0.6);

      expect(_screen(next, focus), _closeToOffset(pointer));
      expect(next.distance, closeTo(pose.distance * 0.6, 1e-9));
      expect(next.yaw, pose.yaw);
      expect(next.pitch, pose.pitch);
    });

    test('zoom never passes the minimum distance', () {
      final next = pose.zoomToward(const Offset(400, 300), _view, 1e-9);
      expect(next.distance, RigCameraState.minDistance);
    });

    test('framing centres the bounds without orbiting', () {
      final bounds = vm.Aabb3.minMax(
        vm.Vector3(-5, 0, -2),
        vm.Vector3(5, 3, 2),
      );
      final next = pose.framing(bounds, _view);

      expect(next.target, _closeToVector(bounds.center));
      expect(next.yaw, pose.yaw);
      expect(next.pitch, pose.pitch);
      for (final corner in [bounds.min, bounds.max]) {
        final p = _screen(next, corner);
        expect(p.dx, inInclusiveRange(0, _view.width));
        expect(p.dy, inInclusiveRange(0, _view.height));
      }
    });
  });

  group('lerp', () {
    test('ends match the inputs', () {
      final other = RigCameraState.preset(RigViewPreset.top);
      final start = RigCameraState.lerp(pose, other, 0);
      final end = RigCameraState.lerp(pose, other, 1);

      expect(start.eye, _closeToVector(pose.eye));
      expect(end.eye, _closeToVector(other.eye));
    });

    test('yaw takes the short way round', () {
      final a = pose.copyWith(yaw: 3.0);
      final b = pose.copyWith(yaw: -3.0);
      final mid = RigCameraState.lerp(a, b, 0.5);

      expect(math.cos(mid.yaw), closeTo(-1, 1e-3));
    });
  });
}
