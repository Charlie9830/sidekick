import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';

/// The primitive a solid is drawn with. Both are fitted to an
/// [OrientedBox]; cylinders run along its height axis.
enum RigSolidShape { box, cylinder }

/// One solid piece of the rig in world space.
@immutable
class RigSolid {
  final OrientedBox box;
  final RigSolidShape shape;

  const RigSolid(this.box, {this.shape = RigSolidShape.box});

  @override
  bool operator ==(Object other) =>
      other is RigSolid && other.box == box && other.shape == shape;

  @override
  int get hashCode => Object.hash(box, shape);
}

/// A fixture in the 3D viewer: its body parts, colour and labels.
///
/// Callers choose [color] (grey, selected, assigned...) so the viewer stays
/// free of any page's notion of selection.
@immutable
class RigFixture {
  /// Fixture uid, reported back by the viewer's tap and hover callbacks.
  final String id;

  final List<RigSolid> parts;
  final Color color;

  /// World positions (mm) of the fixture's cable connectors.
  final List<Vector3> connectors;

  /// Where the label is drawn (world mm).
  final Vector3 labelAnchor;
  final String? label;
  final String? tooltip;

  const RigFixture({
    required this.id,
    required this.parts,
    required this.color,
    required this.labelAnchor,
    this.connectors = const [],
    this.label,
    this.tooltip,
  });

  @override
  bool operator ==(Object other) =>
      other is RigFixture &&
      other.id == id &&
      other.color == color &&
      other.labelAnchor == labelAnchor &&
      other.label == label &&
      other.tooltip == tooltip &&
      _listEquals(other.parts, parts) &&
      _listEquals(other.connectors, connectors);

  @override
  int get hashCode => Object.hash(id, color, labelAnchor, label);
}

/// A polyline drawn through world points, e.g. a cable or a sequence path.
@immutable
class RigLine {
  final List<Vector3> points;
  final Color color;

  /// Line width (mm), so a home run reads thicker than a link.
  final double width;

  /// Shown when the pointer rests on the line, e.g. a cable's length.
  final String? tooltip;

  const RigLine({
    required this.points,
    required this.color,
    this.width = 15,
    this.tooltip,
  });

  @override
  bool operator ==(Object other) =>
      other is RigLine &&
      other.color == color &&
      other.width == width &&
      other.tooltip == tooltip &&
      _listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(color, width, points.length);
}

/// A small coloured marker with an optional label, e.g. a cable header.
@immutable
class RigMarker {
  final Vector3 position;
  final Color color;

  /// Edge length (mm) of the marker.
  final double size;
  final RigSolidShape shape;
  final String? label;

  const RigMarker({
    required this.position,
    required this.color,
    this.size = 200,
    this.shape = RigSolidShape.box,
    this.label,
  });

  @override
  bool operator ==(Object other) =>
      other is RigMarker &&
      other.position == position &&
      other.color == color &&
      other.size == size &&
      other.shape == shape &&
      other.label == label;

  @override
  int get hashCode => Object.hash(position, color, size, shape, label);
}

/// Everything the 3D viewer draws, in world space (mm, Z-up).
///
/// Pages build one of these from their own view models; the viewer turns it
/// into flutter_scene geometry and only rebuilds the parts that changed.
@immutable
class RigSceneModel {
  final List<RigFixture> fixtures;

  /// Truss sticks, each drawn as four chord tubes.
  final List<OrientedBox> trusses;
  final List<RigLine> lines;
  final List<RigMarker> markers;

  const RigSceneModel({
    this.fixtures = const [],
    this.trusses = const [],
    this.lines = const [],
    this.markers = const [],
  });

  bool get isEmpty => fixtures.isEmpty && trusses.isEmpty && markers.isEmpty;

  /// Every point the camera should fit around: fixture parts, trusses and
  /// markers.
  Iterable<Vector3> get extentPoints sync* {
    for (final fixture in fixtures) {
      for (final part in fixture.parts) {
        yield* part.box.corners;
      }
    }
    for (final truss in trusses) {
      yield* truss.corners;
    }
    for (final marker in markers) {
      yield marker.position;
    }
  }
}

bool _listEquals<T>(List<T> a, List<T> b) =>
    identical(a, b) || const ListEquality<Object?>().equals(a, b);
