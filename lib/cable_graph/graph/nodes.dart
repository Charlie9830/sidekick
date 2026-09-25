import 'package:sidekick/cable_graph/cabling/header_resolver.dart';
import 'package:sidekick/cable_graph/graph/edges.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

/// A point in a cable graph. Owns the edges leaving it.
sealed class Node {
  final String id;

  /// World position (mm, Z-up).
  final Vector3 position;
  final Set<Edge> edges;

  const Node({required this.id, required this.position, required this.edges});

  @override
  bool operator ==(Object other) => other is Node && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class FixtureNode extends Node {
  final FixtureTypeModel type;
  final String locationId;

  const FixtureNode({
    required super.id,
    required super.position,
    required super.edges,
    required this.type,
    required this.locationId,
  });
}

/// A lamp-end header of a multicore cable.
sealed class MultiHeaderNode extends Node {
  final String locationId;
  final String outletName;

  /// The lamp header counted for this node, e.g. a Socapex to True1 header.
  final CableType lampHeaderType;

  const MultiHeaderNode({
    required super.id,
    required super.position,
    required super.edges,
    required this.locationId,
    required this.outletName,
    required this.lampHeaderType,
  });
}

class DataMultiHeaderNode extends MultiHeaderNode {
  const DataMultiHeaderNode({
    required super.id,
    required super.position,
    required super.edges,
    required super.locationId,
    required super.outletName,
  }) : super(lampHeaderType: CableType.sneakLampHeader);
}

class PowerMultiHeaderNode extends MultiHeaderNode {
  /// The kind of multicore arriving at this header.
  final HeaderKind kind;

  /// The tail cable this header feeds its fixture runs with.
  final CableType tail;

  const PowerMultiHeaderNode({
    required super.id,
    required super.position,
    required super.edges,
    required super.locationId,
    required super.outletName,
    required super.lampHeaderType,
    required this.kind,
    required this.tail,
  });

  /// The multicore cable arriving at this header.
  CableType get cableType => kind.arrivingCable;
}

class DataPatchHeaderNode extends Node {
  final String outletName;
  final int universe;
  final String locationId;

  /// The data multi outlet this patch travels inside, or empty when it is run
  /// on its own.
  final String parentMultiOutletId;

  const DataPatchHeaderNode({
    required super.id,
    required super.position,
    required super.edges,
    required this.outletName,
    required this.universe,
    required this.locationId,
    required this.parentMultiOutletId,
  });
}

/// The root of a location's breakout, fed from the racks.
class LocationNode extends Node {
  final String locationId;

  const LocationNode({
    required super.position,
    required super.edges,
    required this.locationId,
  }) : super(id: locationId);
}

/// A point where a cable is broken because it crosses a truss join.
///
/// Inserted between two endpoints when a run spans one or more joins, so the
/// run is represented as a chain of shorter [CableEdge]s.
class TrussBreakNode extends Node {
  final String locationId;

  const TrussBreakNode({
    required super.id,
    required super.position,
    required super.edges,
    required this.locationId,
  });
}
