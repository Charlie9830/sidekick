import 'dart:math';

import 'package:sidekick/redux/models/truss_model.dart';

/// Distance (in mm) within which a fixture is considered to be hanging from a
/// truss stick. Beyond this the fixture is treated as floor / un-trussed and its
/// cables are never broken at a join.
const double kTrussAssignmentToleranceMm = 2500;

/// Tolerance (in mm) for deciding that two stick end-points coincide and that
/// the sticks therefore share a join.
const double kJoinCoincidenceToleranceMm = 250;

/// A 3D point expressed as a record. All coordinates are in millimetres.
typedef Point3 = ({double x, double y, double z});

/// Where a fixture hangs: which truss line and the index of the stick within it.
class TrussAssignment {
  final String lineId;
  final int sectionIndex;
  final String stickUid;

  const TrussAssignment({
    required this.lineId,
    required this.sectionIndex,
    required this.stickUid,
  });
}

/// The result of splitting a cable run at the truss joins it crosses.
///
/// [segmentLengths] always has one more entry than [breakPoints]. Lengths are
/// the raw euclidean length (mm) of each segment, before rounding to a cable
/// breakpoint.
class RunSplit {
  final List<double> segmentLengths;
  final List<Point3> breakPoints;

  const RunSplit({required this.segmentLengths, required this.breakPoints});

  bool get hasBreaks => breakPoints.isNotEmpty;
}

class _StickInfo {
  final String uid;
  final Point3 centre;
  final Point3 axis;
  final double halfLength;
  final double halfWidth;
  final double halfHeight;
  String lineId = '';
  int index = 0;

  _StickInfo({
    required this.uid,
    required this.centre,
    required this.axis,
    required this.halfLength,
    required this.halfWidth,
    required this.halfHeight,
  });

  Point3 get endA => (
        x: centre.x - axis.x * halfLength,
        y: centre.y - axis.y * halfLength,
        z: centre.z - axis.z * halfLength,
      );

  Point3 get endB => (
        x: centre.x + axis.x * halfLength,
        y: centre.y + axis.y * halfLength,
        z: centre.z + axis.z * halfLength,
      );
}

/// Pre-computed truss topology: each stick's line membership and ordering, plus
/// the world-space join points between consecutive sticks of a line.
///
/// Joins are derived purely from geometry: each [TrussModel] is one physical
/// stick and a join is the boundary where two adjacent collinear sticks meet.
class TrussGeometry {
  final Map<String, _StickInfo> _sticks;

  /// Ordered join points per line. `_joinsByLine[lineId][k]` is the join between
  /// the stick at index `k` and the stick at index `k + 1`.
  final Map<String, List<Point3>> _joinsByLine;

  TrussGeometry._(this._sticks, this._joinsByLine);

  /// Builds the topology from imported [trusses].
  factory TrussGeometry.fromTrusses(Iterable<TrussModel> trusses) {
    final sticks = <String, _StickInfo>{};
    for (final truss in trusses) {
      if (truss.length <= 0) continue;
      final radians = truss.rotationZ * pi / 180.0;
      sticks[truss.uid] = _StickInfo(
        uid: truss.uid,
        centre: (x: truss.x, y: truss.y, z: truss.z),
        axis: (x: cos(radians), y: sin(radians), z: 0),
        halfLength: truss.length / 2,
        halfWidth: truss.width / 2,
        halfHeight: truss.height / 2,
      );
    }

    _groupAndOrderLines(sticks);
    final joins = _buildJoinPoints(sticks);

    return TrussGeometry._(sticks, joins);
  }

  bool get isEmpty => _sticks.isEmpty;

  /// Assigns each fixture to the nearest truss stick by closest point on the
  /// stick's oriented bounding box, gated by [kTrussAssignmentToleranceMm].
  ///
  /// Fixtures with no truss within tolerance are omitted (treated as floor).
  Map<String, TrussAssignment> assignFixtures(
    Iterable<({String uid, double x, double y, double z})> fixtures,
  ) {
    final result = <String, TrussAssignment>{};
    if (_sticks.isEmpty) return result;

    for (final fixture in fixtures) {
      final point = (x: fixture.x, y: fixture.y, z: fixture.z);
      _StickInfo? nearest;
      double nearestDistance = double.infinity;

      for (final stick in _sticks.values) {
        final distance = _distanceToBox(point, stick);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = stick;
        }
      }

      if (nearest != null && nearestDistance <= kTrussAssignmentToleranceMm) {
        result[fixture.uid] = TrussAssignment(
          lineId: nearest.lineId,
          sectionIndex: nearest.index,
          stickUid: nearest.uid,
        );
      }
    }

    return result;
  }

  /// Splits a straight run between [from] and [to] at the joins it crosses.
  ///
  /// Same-line runs cross `|indexFrom - indexTo|` joins (the sections between the
  /// two assigned sticks). Cross-line runs route via the line ends, crossing the
  /// joins of both lines that fall along the run. Unassigned endpoints yield a
  /// single unbroken segment.
  RunSplit splitRun({
    required Point3 from,
    required Point3 to,
    required TrussAssignment? fromAssignment,
    required TrussAssignment? toAssignment,
  }) {
    final total = _distance(from, to);

    if (fromAssignment == null || toAssignment == null || total == 0) {
      return RunSplit(segmentLengths: [total], breakPoints: const []);
    }

    final List<Point3> candidateJoins;
    if (fromAssignment.lineId == toAssignment.lineId) {
      candidateJoins = _joinsBetween(
        fromAssignment.lineId,
        fromAssignment.sectionIndex,
        toAssignment.sectionIndex,
      );
    } else {
      candidateJoins = [
        ...?_joinsByLine[fromAssignment.lineId],
        ...?_joinsByLine[toAssignment.lineId],
      ];
    }

    if (candidateJoins.isEmpty) {
      return RunSplit(segmentLengths: [total], breakPoints: const []);
    }

    // Project each join onto the run, keep the ones that fall strictly inside,
    // then order them from `from` to `to`.
    final parameters = candidateJoins
        .map((join) => _projectParameter(from, to, join))
        .where((t) => t > 1e-6 && t < 1 - 1e-6)
        .toList()
      ..sort();

    if (parameters.isEmpty) {
      return RunSplit(segmentLengths: [total], breakPoints: const []);
    }

    final breakPoints =
        parameters.map((t) => _lerp(from, to, t)).toList(growable: false);

    final boundaries = [0.0, ...parameters, 1.0];
    final segmentLengths = [
      for (var i = 0; i < boundaries.length - 1; i++)
        total * (boundaries[i + 1] - boundaries[i]),
    ];

    return RunSplit(segmentLengths: segmentLengths, breakPoints: breakPoints);
  }

  List<Point3> _joinsBetween(String lineId, int indexA, int indexB) {
    final joins = _joinsByLine[lineId];
    if (joins == null) return const [];

    final low = min(indexA, indexB);
    final high = max(indexA, indexB);

    // Join `k` separates sticks `k` and `k + 1`, so the joins between two sticks
    // are those with index in [low, high).
    return [
      for (var k = low; k < high && k < joins.length; k++) joins[k],
    ];
  }

  /// Groups sticks into collinear, contiguous lines via union-find on coincident
  /// end-points, then orders each line along its axis.
  static void _groupAndOrderLines(Map<String, _StickInfo> sticks) {
    final stickList = sticks.values.toList();
    final parent = {for (final stick in stickList) stick.uid: stick.uid};

    String find(String id) {
      var root = id;
      while (parent[root] != root) {
        root = parent[root]!;
      }
      return root;
    }

    void union(String a, String b) => parent[find(a)] = find(b);

    for (var i = 0; i < stickList.length; i++) {
      for (var j = i + 1; j < stickList.length; j++) {
        if (_areJoined(stickList[i], stickList[j])) {
          union(stickList[i].uid, stickList[j].uid);
        }
      }
    }

    final byLine = <String, List<_StickInfo>>{};
    for (final stick in stickList) {
      byLine.putIfAbsent(find(stick.uid), () => []).add(stick);
    }

    for (final entry in byLine.entries) {
      final lineId = entry.key;
      final lineSticks = entry.value;
      final direction = lineSticks.first.axis;

      lineSticks.sort((a, b) =>
          _projectOntoAxis(a.centre, direction)
              .compareTo(_projectOntoAxis(b.centre, direction)));

      for (var index = 0; index < lineSticks.length; index++) {
        lineSticks[index].lineId = lineId;
        lineSticks[index].index = index;
      }
    }
  }

  static Map<String, List<Point3>> _buildJoinPoints(
    Map<String, _StickInfo> sticks,
  ) {
    final byLine = <String, List<_StickInfo>>{};
    for (final stick in sticks.values) {
      byLine.putIfAbsent(stick.lineId, () => []).add(stick);
    }

    final result = <String, List<Point3>>{};
    for (final entry in byLine.entries) {
      final ordered = entry.value..sort((a, b) => a.index.compareTo(b.index));
      final joins = <Point3>[];
      for (var i = 0; i < ordered.length - 1; i++) {
        joins.add(_midpoint(ordered[i].endB, ordered[i + 1].endA));
      }
      result[entry.key] = joins;
    }
    return result;
  }

  /// Two sticks join when their axes are parallel and they share an end-point.
  static bool _areJoined(_StickInfo a, _StickInfo b) {
    final cross = (a.axis.x * b.axis.y) - (a.axis.y * b.axis.x);
    if (cross.abs() > 0.05) return false; // ~3 degrees of parallelism slack.

    final ends = [a.endA, a.endB];
    final otherEnds = [b.endA, b.endB];
    for (final end in ends) {
      for (final otherEnd in otherEnds) {
        if (_distance(end, otherEnd) <= kJoinCoincidenceToleranceMm) {
          return true;
        }
      }
    }
    return false;
  }

  /// Shortest distance from [point] to the stick's oriented bounding box.
  static double _distanceToBox(Point3 point, _StickInfo stick) {
    // Transform the point into the stick's local frame (axis = local X). Only
    // rotation about Z is modelled, which holds for level trusses.
    final dx = point.x - stick.centre.x;
    final dy = point.y - stick.centre.y;
    final dz = point.z - stick.centre.z;

    final localX = dx * stick.axis.x + dy * stick.axis.y;
    final localY = -dx * stick.axis.y + dy * stick.axis.x;
    final localZ = dz;

    final clampedX = localX.clamp(-stick.halfLength, stick.halfLength);
    final clampedY = localY.clamp(-stick.halfWidth, stick.halfWidth);
    final clampedZ = localZ.clamp(-stick.halfHeight, stick.halfHeight);

    final ox = localX - clampedX;
    final oy = localY - clampedY;
    final oz = localZ - clampedZ;
    return sqrt(ox * ox + oy * oy + oz * oz);
  }

  static double _projectParameter(Point3 from, Point3 to, Point3 point) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dz = to.z - from.z;
    final lengthSquared = dx * dx + dy * dy + dz * dz;
    if (lengthSquared == 0) return 0;
    final dot = (point.x - from.x) * dx +
        (point.y - from.y) * dy +
        (point.z - from.z) * dz;
    return dot / lengthSquared;
  }

  static double _projectOntoAxis(Point3 point, Point3 axis) =>
      point.x * axis.x + point.y * axis.y + point.z * axis.z;

  static Point3 _lerp(Point3 from, Point3 to, double t) => (
        x: from.x + (to.x - from.x) * t,
        y: from.y + (to.y - from.y) * t,
        z: from.z + (to.z - from.z) * t,
      );

  static Point3 _midpoint(Point3 a, Point3 b) =>
      (x: (a.x + b.x) / 2, y: (a.y + b.y) / 2, z: (a.z + b.z) / 2);

  static double _distance(Point3 a, Point3 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}
