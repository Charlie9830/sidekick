import 'package:sidekick/cable_graph/truss_geometry.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';

/// A point a cable is routed to or from: a position on a fixture.
///
/// [fixtureId] ties the point to the fixture's truss assignment, so a cable to
/// any point on a trussed fixture follows that fixture's truss run.
typedef RoutePoint = ({String fixtureId, Vector3 position});

/// Measures cable runs, following truss chords where fixtures are trussed.
class CableRouter {
  final TrussGeometry _geometry;
  final Map<String, TrussAssignment> _fixtureAssignments;

  CableRouter._(this._geometry, this._fixtureAssignments);

  /// Assigns each fixture in [fixtures] (by its centre) to its nearest truss
  /// run, if any.
  factory CableRouter.build({
    required Iterable<TrussModel> trusses,
    required Iterable<FixtureModel> fixtures,
  }) {
    final geometry = TrussGeometry.fromTrusses(trusses);
    final assignments = geometry.isEmpty
        ? <String, TrussAssignment>{}
        : geometry.assignFixtures(
            fixtures.map((fix) => (uid: fix.uid, x: fix.x, y: fix.y, z: fix.z)),
          );

    return CableRouter._(geometry, assignments);
  }

  /// Length of a home run from a header at [from] to [to].
  ///
  /// Trussed fixtures follow their run's chord (entering at the nearest point);
  /// floor fixtures fall back to a straight line plus a [kFloorRiserMm] riser.
  double homeRunLength({required Vector3 from, required RoutePoint to}) {
    final assignment = _assignmentOf(to);
    final alongTruss = assignment == null
        ? null
        : _geometry.homeRunLength(from: from, assignment: assignment);

    return alongTruss ?? from.distanceTo(to.position) + kFloorRiserMm;
  }

  /// Splits a link run into segments at each truss join it crosses.
  RunSplit splitLink({required RoutePoint from, required RoutePoint to}) {
    return _geometry.splitRun(
      from: from.position,
      to: to.position,
      fromAssignment: _assignmentOf(from),
      toAssignment: _assignmentOf(to),
    );
  }

  /// Where [point] meets its fixture's truss run, or null when the fixture is
  /// not trussed.
  TrussAssignment? _assignmentOf(RoutePoint point) {
    final fixtureAssignment = _fixtureAssignments[point.fixtureId];
    if (fixtureAssignment == null) return null;

    return _geometry.assignmentAt(fixtureAssignment, point.position) ??
        fixtureAssignment;
  }
}
