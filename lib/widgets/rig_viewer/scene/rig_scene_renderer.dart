import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_scene/scene.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show Color;
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';
import 'package:sidekick/widgets/rig_viewer/scene/picking.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';
import 'package:sidekick/widgets/rig_viewer/scene/world_space.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Edge length (mm) of a connector box.
const double kConnectorSizeMm = 40;

/// Diameter (mm) of a truss chord tube (standard 48.3 mm scaffold tube).
const double _kTrussTubeMm = 48;

/// Spacing (mm) of the floor grid.
const double _kGridSpacingMm = 1000;

/// Margin (mm) the floor grid extends past the rig.
const double _kGridMarginMm = 2000;

/// Owns the flutter_scene [Scene] for a [RigSceneModel] and keeps it in sync.
///
/// Every solid is an instance of one shared unit cube or unit cylinder, scaled
/// into place by [OrientedBox.sceneTransform] and tinted by its instance
/// colour, so a whole rig is a handful of draw calls and recolouring needs no
/// new geometry. Lines are batched by colour and width. [update] only rebuilds
/// the layers whose part of the model changed.
class RigSceneRenderer {
  final Scene scene = Scene();

  final InstancedMesh _boxes = InstancedMesh(
    geometry: CuboidGeometry(vm.Vector3.all(1)),
    material: _solidMaterial(),
  );
  final InstancedMesh _cylinders = InstancedMesh(
    geometry: CylinderGeometry(radialSegments: 16),
    material: _solidMaterial(),
  );
  final InstancedMesh _connectorBoxes = InstancedMesh(
    geometry: CuboidGeometry(vm.Vector3.all(1)),
    material: _solidMaterial(),
  );

  final Node _connectorsNode = Node(name: 'connectors');
  final Node _linesNode = Node(name: 'lines');
  final Node _gridNode = Node(name: 'grid');

  RigSceneModel _model = const RigSceneModel();
  List<PickTarget> _pickTargets = const [];
  vm.Aabb3? _bounds;

  RigSceneRenderer() {
    _connectorsNode.addComponent(InstancedMeshComponent(_connectorBoxes));
    scene.addAll([
      Node(name: 'boxes')..addComponent(InstancedMeshComponent(_boxes)),
      Node(name: 'cylinders')..addComponent(InstancedMeshComponent(_cylinders)),
      _connectorsNode,
      _linesNode,
      _gridNode,
    ]);
  }

  /// The pickable solids of every fixture, in world space.
  List<PickTarget> get pickTargets => _pickTargets;

  /// Scene-space bounds of everything worth framing, or null for an empty
  /// rig.
  vm.Aabb3? get bounds => _bounds;

  set showConnectors(bool value) => _connectorsNode.visible = value;

  /// Brings the scene in line with [model].
  void update(RigSceneModel model) {
    final previous = _model;
    _model = model;

    final solidsChanged =
        !_equal(previous.fixtures, model.fixtures) ||
        !_equal(previous.trusses, model.trusses) ||
        !_equal(previous.markers, model.markers);
    if (solidsChanged) {
      _rebuildSolids(model);
      _rebuildBounds(model);
    }
    if (!_equal(previous.lines, model.lines)) {
      _rebuildLines(model.lines);
    }
  }

  void _rebuildSolids(RigSceneModel model) {
    _boxes.clearInstances();
    _cylinders.clearInstances();
    _connectorBoxes.clearInstances();

    void add(RigSolid solid, Color color) {
      final mesh = switch (solid.shape) {
        RigSolidShape.box => _boxes,
        RigSolidShape.cylinder => _cylinders,
      };
      mesh.addInstance(solid.box.sceneTransform, color: _linear(color));
    }

    final connectorColor = _linear(SidekickColors.rigConnector);
    for (final fixture in model.fixtures) {
      for (final part in fixture.parts) {
        add(part, fixture.color);
      }
      for (final connector in fixture.connectors) {
        _connectorBoxes.addInstance(
          OrientedBox.cube(
            center: connector,
            size: kConnectorSizeMm,
          ).sceneTransform,
          color: connectorColor,
        );
      }
    }
    for (final truss in model.trusses) {
      for (final chord in _trussChords(truss)) {
        add(chord, SidekickColors.rigTruss);
      }
    }
    for (final marker in model.markers) {
      add(
        RigSolid(
          OrientedBox.cube(center: marker.position, size: marker.size),
          shape: marker.shape,
        ),
        marker.color,
      );
    }

    _pickTargets = [
      for (final fixture in model.fixtures)
        for (final part in fixture.parts) (id: fixture.id, box: part.box),
    ];
  }

  void _rebuildBounds(RigSceneModel model) {
    final points = model.extentPoints.toList();
    if (points.isEmpty) {
      _bounds = null;
      _gridNode.removeAll();
      return;
    }

    final scenePoints = points.map(WorldSpace.toScene).toList();
    final bounds = vm.Aabb3.minMax(
      scenePoints.first.clone(),
      scenePoints.first.clone(),
    );
    for (final point in scenePoints.skip(1)) {
      bounds.hullPoint(point);
    }
    _bounds = bounds;
    _rebuildGrid(points);
  }

  void _rebuildLines(List<RigLine> lines) {
    _linesNode.removeAll();
    final groups = groupBy(lines, (line) => (line.color, line.width));
    for (final MapEntry(key: (color, width), value: group) in groups.entries) {
      final segments = <Vector3>[
        for (final line in group)
          for (var i = 0; i < line.points.length - 1; i++) ...[
            line.points[i],
            line.points[i + 1],
          ],
      ];
      if (segments.isEmpty) continue;
      _linesNode.add(_segmentsNode(segments, color, width));
    }
  }

  /// A 1 m floor grid on Z = 0 under the rig, plus the point-of-origin axes.
  void _rebuildGrid(List<Vector3> points) {
    _gridNode.removeAll();

    double snapDown(double v) =>
        ((v - _kGridMarginMm) / _kGridSpacingMm).floorToDouble() *
        _kGridSpacingMm;
    double snapUp(double v) =>
        ((v + _kGridMarginMm) / _kGridSpacingMm).ceilToDouble() *
        _kGridSpacingMm;

    final minX = snapDown(math.min(0, points.map((p) => p.x).min));
    final maxX = snapUp(math.max(0, points.map((p) => p.x).max));
    final minY = snapDown(math.min(0, points.map((p) => p.y).min));
    final maxY = snapUp(math.max(0, points.map((p) => p.y).max));

    final grid = <Vector3>[
      for (var x = minX; x <= maxX; x += _kGridSpacingMm) ...[
        Vector3(x, minY, 0),
        Vector3(x, maxY, 0),
      ],
      for (var y = minY; y <= maxY; y += _kGridSpacingMm) ...[
        Vector3(minX, y, 0),
        Vector3(maxX, y, 0),
      ],
    ];

    _gridNode
      ..add(_segmentsNode(grid, SidekickColors.rigGrid, 10))
      ..add(
        _segmentsNode(
          const [Vector3.zero, Vector3(1000, 0, 0)],
          SidekickColors.powerRun,
          25,
        ),
      )
      ..add(
        _segmentsNode(
          const [Vector3.zero, Vector3(0, 1000, 0)],
          SidekickColors.success,
          25,
        ),
      );
  }

  /// A batch of world-space segments (consecutive point pairs) drawn as
  /// [width] mm lines.
  static Node _segmentsNode(List<Vector3> points, Color color, double width) {
    final positions = Float32List(points.length * 3);
    for (var i = 0; i < points.length; i++) {
      final p = WorldSpace.toScene(points[i]);
      positions
        ..[i * 3] = p.x
        ..[i * 3 + 1] = p.y
        ..[i * 3 + 2] = p.z;
    }

    return Node(
      mesh: Mesh(
        LineSegmentsGeometry(
          LineSegmentData(positions: positions),
          width: width / kMillimetresPerSceneUnit,
        ),
        UnlitMaterial()..baseColorFactor = _linear(color),
      ),
    );
  }

  /// The four chord tubes of a truss stick, inset so they sit inside its box.
  static List<RigSolid> _trussChords(OrientedBox truss) {
    final halfWidth = math.max(truss.width - _kTrussTubeMm, 0) / 2;
    final halfHeight = math.max(truss.height - _kTrussTubeMm, 0) / 2;

    return [
      for (final w in const [-1, 1])
        for (final h in const [-1, 1])
          RigSolid(
            OrientedBox(
              center:
                  truss.center +
                  truss.widthAxis * (w * halfWidth) +
                  truss.heightAxis * (h * halfHeight),
              // Cylinders run along the height axis, so the tube's height is
              // the truss length.
              heightAxis: truss.lengthAxis,
              lengthAxis: truss.widthAxis,
              widthAxis: truss.heightAxis,
              height: truss.length,
              length: _kTrussTubeMm,
              width: _kTrussTubeMm,
            ),
            shape: RigSolidShape.cylinder,
          ),
    ];
  }

  static PhysicallyBasedMaterial _solidMaterial() => PhysicallyBasedMaterial()
    ..metallicFactor = 0
    ..roughnessFactor = 0.85;

  /// [color] as a linear-light RGBA vector, the space the shaders blend in.
  static vm.Vector4 _linear(Color color) {
    double channel(double c) => math.pow(c, 2.2).toDouble();
    return vm.Vector4(channel(color.r), channel(color.g), channel(color.b), 1);
  }

  static bool _equal<T>(List<T> a, List<T> b) =>
      identical(a, b) || const ListEquality<Object?>().equals(a, b);
}
