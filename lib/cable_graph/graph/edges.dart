import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/cable_model.dart';

/// The role a cable plays in a location's breakout.
enum CableRunType {
  /// Fixture to fixture.
  link,

  /// Header to the first fixture of a circuit or universe.
  fixtureRun,

  /// Location to a multi header.
  homeRun,
}

/// A directed connection between two nodes of a cable graph, by node id.
sealed class Edge {
  final String from;
  final String to;

  const Edge({required this.from, required this.to});
}

/// A physical cable that is counted in the cable list.
class CableEdge extends Edge {
  /// The routed length in mm, before rounding up to a stock length.
  final double euclidianLength;

  /// The stock length in metres that covers [euclidianLength].
  final double length;
  final CableType type;
  final String locationId;
  final CableRunType runType;

  /// Where the cable plugs in at each end (e.g. a fixture's connector), when
  /// that differs from the end node's own position.
  final Vector3? fromPoint;
  final Vector3? toPoint;

  /// An adaptor needed where this cable meets a connector it does not fit,
  /// counted alongside the cable itself.
  final CableType? adaptorType;

  const CableEdge({
    required super.from,
    required super.to,
    required this.euclidianLength,
    required this.length,
    required this.type,
    required this.locationId,
    required this.runType,
    this.fromPoint,
    this.toPoint,
    this.adaptorType,
  });
}

/// A logical relationship that is not a cable in its own right, such as a data
/// patch travelling inside a sneak.
class LogicalEdge extends Edge {
  const LogicalEdge({required super.from, required super.to});
}
