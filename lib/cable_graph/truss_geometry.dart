import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/truss_model.dart';

/// Distance (in mm) within which a fixture is considered to be hanging from a
/// truss stick. Beyond this the fixture is treated as floor / un-trussed and its
/// cables are never broken at a join.
const double kTrussAssignmentToleranceMm = 2500;

/// Tolerance (in mm) for deciding that two stick end-points coincide and that
/// the sticks therefore share a join (whether in-line or around a corner).
const double kJoinCoincidenceToleranceMm = 250;

/// Cables are dressed to the truss chord that is *furthest* from the fixtures,
/// but only if that chord is no more than this far beyond the nearest chord.
/// This picks the far rail for normal box truss while guarding against routing
/// cable to an absurd corner on an oversized or compound truss line.
const double kFurthestChordCapMm = 800;

/// The vertical allowance (in mm) added at each end of a run for a floor
/// (un-trussed) fixture, standing in for the drop from the cable to the fixture.
const double kFloorRiserMm = 500;

/// Where a fixture attaches to a truss run: which run, and its foot position and
/// riser on that run's chosen cable chord.
class TrussAssignment {
  /// Id of the truss run the fixture hangs from.
  final String runId;

  /// Arc-length (mm) of the fixture's foot along the run's chosen chord.
  final double s;

  /// Perpendicular distance (mm) from the fixture to that chord.
  final double riser;

  const TrussAssignment({
    required this.runId,
    required this.s,
    required this.riser,
  });
}

/// The result of routing a cable run, split at the truss joins it crosses.
///
/// [segmentLengths] always has one more entry than [breakPoints]. Lengths are
/// the raw run length (mm) of each segment — including the vertical risers at
/// the two ends — before rounding to a cable breakpoint.
class RunSplit {
  final List<double> segmentLengths;
  final List<Vector3> breakPoints;

  const RunSplit({required this.segmentLengths, required this.breakPoints});

  bool get hasBreaks => breakPoints.isNotEmpty;
}

/// One physical truss stick, modelled as an oriented box.
class _Stick {
  final String uid;
  final Vector3 center;
  final Vector3 lAxis;
  final Vector3 wAxis;
  final Vector3 hAxis;
  final double halfL;
  final double halfW;
  final double halfH;

  /// The stick's ends after it is oriented within its run (start → finish along
  /// the run direction). Defaults to the raw length-axis ends.
  Vector3 startEnd;
  Vector3 finishEnd;

  _Stick({
    required this.uid,
    required this.center,
    required this.lAxis,
    required this.wAxis,
    required this.hAxis,
    required this.halfL,
    required this.halfW,
    required this.halfH,
  })  : startEnd = center - lAxis * halfL,
        finishEnd = center + lAxis * halfL;

  Vector3 get rawEnd0 => center - lAxis * halfL;
  Vector3 get rawEnd1 => center + lAxis * halfL;

  /// Shortest distance from [p] to this stick's oriented bounding box.
  double distanceToBox(Vector3 p) {
    final d = p - center;
    final lx = d.dot(lAxis);
    final ly = d.dot(wAxis);
    final lz = d.dot(hAxis);
    final ox = lx - lx.clamp(-halfL, halfL);
    final oy = ly - ly.clamp(-halfW, halfW);
    final oz = lz - lz.clamp(-halfH, halfH);
    return math.sqrt(ox * ox + oy * oy + oz * oz);
  }
}

/// A connected chain of sticks (possibly bending around corners), plus the
/// single cable chord chosen for it once its fixtures are known.
class _Run {
  final String id;
  final List<_Stick> sticks;

  /// The chosen cable chord as a polyline, set by [chooseChord].
  _Polyline? chord;

  /// Arc-lengths (mm) along [chord] of the interior joins between sticks.
  List<double> joinArcLengths = const [];

  _Run(this.id, this.sticks);

  /// Picks the cable chord: the longitudinal edge furthest from [fixtures] whose
  /// mean fixture distance is within [kFurthestChordCapMm] of the nearest edge.
  void chooseChord(List<Vector3> fixtures) {
    const patterns = [(-1.0, -1.0), (-1.0, 1.0), (1.0, -1.0), (1.0, 1.0)];

    final candidates = patterns.map((pattern) {
      final built = _buildChord(pattern.$1, pattern.$2);
      final mean = fixtures.isEmpty
          ? 0.0
          : fixtures
                  .map((f) => built.poly.project(f).distance)
                  .reduce((a, b) => a + b) /
              fixtures.length;
      return (poly: built.poly, joins: built.joinArcLengths, mean: mean);
    }).toList();

    final near = candidates.map((c) => c.mean).reduce(math.min);
    final eligible =
        candidates.where((c) => c.mean <= near + kFurthestChordCapMm);
    final chosen = eligible.reduce((a, b) => b.mean > a.mean ? b : a);

    chord = chosen.poly;
    joinArcLengths = chosen.joins;
  }

  ({_Polyline poly, List<double> joinArcLengths}) _buildChord(
      double signW, double signH) {
    final rawPoints = <Vector3>[];
    final joinIndices = <int>[];

    for (var i = 0; i < sticks.length; i++) {
      final stick = sticks[i];
      final offset =
          stick.wAxis * (signW * stick.halfW) + stick.hAxis * (signH * stick.halfH);
      rawPoints.add(stick.startEnd + offset);
      rawPoints.add(stick.finishEnd + offset);
      if (i < sticks.length - 1) joinIndices.add(rawPoints.length - 1);
    }

    // Arc-length up to each raw point, used for the join positions. Dedup in
    // [_Polyline] only removes zero-length segments, so these stay valid.
    final cumulative = <double>[0];
    for (var i = 1; i < rawPoints.length; i++) {
      cumulative.add(cumulative[i - 1] + rawPoints[i - 1].distanceTo(rawPoints[i]));
    }

    return (
      poly: _Polyline(rawPoints),
      joinArcLengths: joinIndices.map((i) => cumulative[i]).toList(),
    );
  }
}

/// A 3D polyline with arc-length helpers, expressed in world millimetres.
class _Polyline {
  final List<Vector3> points;
  final List<double> _cumulative;

  _Polyline._(this.points, this._cumulative);

  factory _Polyline(List<Vector3> rawPoints) {
    final points = <Vector3>[];
    for (final p in rawPoints) {
      if (points.isEmpty || points.last.distanceTo(p) > 1e-6) points.add(p);
    }
    if (points.isEmpty) points.add(Vector3.zero);

    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative[i - 1] + points[i - 1].distanceTo(points[i]));
    }

    return _Polyline._(points, cumulative);
  }

  double get length => _cumulative.last;

  /// The arc-length of [p]'s closest foot on the polyline, and its distance.
  ({double s, double distance}) project(Vector3 p) {
    if (points.length == 1) {
      return (s: 0, distance: p.distanceTo(points.first));
    }

    var bestDistance = double.infinity;
    var bestS = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final ab = points[i + 1] - a;
      final segLengthSquared = ab.dot(ab);
      final t = segLengthSquared == 0
          ? 0.0
          : ((p - a).dot(ab) / segLengthSquared).clamp(0.0, 1.0);
      final foot = a + ab * t;
      final distance = p.distanceTo(foot);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestS = _cumulative[i] + (_cumulative[i + 1] - _cumulative[i]) * t;
      }
    }
    return (s: bestS, distance: bestDistance);
  }

  /// The world point at arc-length [s] along the polyline.
  Vector3 pointAt(double s) {
    if (s <= 0) return points.first;
    if (s >= length) return points.last;
    for (var i = 0; i < points.length - 1; i++) {
      if (s <= _cumulative[i + 1]) {
        final segLength = _cumulative[i + 1] - _cumulative[i];
        final t = segLength == 0 ? 0.0 : (s - _cumulative[i]) / segLength;
        return points[i] + (points[i + 1] - points[i]) * t;
      }
    }
    return points.last;
  }
}

/// Pre-computed truss topology: sticks grouped into connected runs, each with a
/// single cable chord chosen once its fixtures are known.
///
/// Cable lengths follow the chord: a fixture-to-fixture link rises to the chord,
/// tracks along it (breaking at each join it crosses), and drops to the next
/// fixture. Home runs follow the chord too, entering at the point nearest the
/// source. Fixtures with no truss within tolerance fall back to a flat run with
/// a fixed [kFloorRiserMm] allowance at each end.
class TrussGeometry {
  final List<_Run> _runs;
  final Map<String, _Run> _runById;
  final Map<String, _Run> _runByStickUid;

  TrussGeometry._(this._runs, this._runById, this._runByStickUid);

  /// Builds the topology from imported [trusses].
  factory TrussGeometry.fromTrusses(Iterable<TrussModel> trusses) {
    final sticks = <_Stick>[];
    for (final truss in trusses) {
      if (truss.length <= 0) continue;
      sticks.add(_Stick(
        uid: truss.uid,
        center: truss.center,
        lAxis: truss.lengthAxis.normalized,
        wAxis: truss.widthAxis.normalized,
        hAxis: truss.heightAxis.normalized,
        halfL: truss.length / 2,
        halfW: truss.width / 2,
        halfH: truss.height / 2,
      ));
    }

    final runs = _groupIntoRuns(sticks);
    final runById = {for (final run in runs) run.id: run};
    final runByStickUid = <String, _Run>{
      for (final run in runs)
        for (final stick in run.sticks) stick.uid: run,
    };

    return TrussGeometry._(runs, runById, runByStickUid);
  }

  bool get isEmpty => _runs.isEmpty;

  /// Assigns each fixture to the nearest truss stick (by oriented-box distance,
  /// gated by [kTrussAssignmentToleranceMm]), then resolves its foot and riser
  /// on that run's chosen chord. Un-trussed fixtures are omitted.
  Map<String, TrussAssignment> assignFixtures(
    Iterable<({String uid, double x, double y, double z})> fixtures,
  ) {
    final result = <String, TrussAssignment>{};
    if (_runs.isEmpty) return result;

    final fixturePositions = <String, Vector3>{};
    final runOfFixture = <String, _Run>{};

    for (final fixture in fixtures) {
      final point = Vector3(fixture.x, fixture.y, fixture.z);
      _Stick? nearest;
      var nearestDistance = double.infinity;
      for (final run in _runs) {
        for (final stick in run.sticks) {
          final distance = stick.distanceToBox(point);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = stick;
          }
        }
      }

      if (nearest != null && nearestDistance <= kTrussAssignmentToleranceMm) {
        fixturePositions[fixture.uid] = point;
        runOfFixture[fixture.uid] = _runByStickUid[nearest.uid]!;
      }
    }

    final fixturesByRun = <_Run, List<String>>{};
    runOfFixture.forEach((uid, run) =>
        fixturesByRun.putIfAbsent(run, () => []).add(uid));

    fixturesByRun.forEach((run, uids) {
      run.chooseChord(uids.map((uid) => fixturePositions[uid]!).toList());
      final chord = run.chord!;
      for (final uid in uids) {
        final projection = chord.project(fixturePositions[uid]!);
        result[uid] = TrussAssignment(
          runId: run.id,
          s: projection.s,
          riser: projection.distance,
        );
      }
    });

    return result;
  }

  /// Splits a fixture-to-fixture run into segments, following the truss chord
  /// when both fixtures share a run and breaking at each join between them.
  ///
  /// Same-run runs route `riser → along-chord → riser`, split at the crossed
  /// joins. Every other case (floor, cross-run, or a run without a chord) yields
  /// a single unbroken `riser + horizontal + riser` segment.
  RunSplit splitRun({
    required Vector3 from,
    required Vector3 to,
    required TrussAssignment? fromAssignment,
    required TrussAssignment? toAssignment,
  }) {
    if (fromAssignment != null &&
        toAssignment != null &&
        fromAssignment.runId == toAssignment.runId) {
      final run = _runById[fromAssignment.runId];
      if (run?.chord != null) {
        return _splitAlongRun(run!, fromAssignment, toAssignment);
      }
    }

    final riserFrom = fromAssignment?.riser ?? kFloorRiserMm;
    final riserTo = toAssignment?.riser ?? kFloorRiserMm;
    final total = riserFrom + _horizontalDistance(from, to) + riserTo;
    return RunSplit(segmentLengths: [total], breakPoints: const []);
  }

  /// Length of a home run from [from] to a fixture, following the fixture's run
  /// and entering at the point on the chord nearest [from].
  ///
  /// Returns `null` when the fixture's run has no chord, so the caller can apply
  /// the floor fallback.
  double? homeRunLength({
    required Vector3 from,
    required TrussAssignment assignment,
  }) {
    final chord = _runById[assignment.runId]?.chord;
    if (chord == null) return null;

    final entry = chord.project(from);
    final along = (assignment.s - entry.s).abs();
    return entry.distance + along + assignment.riser;
  }

  RunSplit _splitAlongRun(_Run run, TrussAssignment a, TrussAssignment b) {
    final chord = run.chord!;
    final low = math.min(a.s, b.s);
    final high = math.max(a.s, b.s);

    final joinsBetween = run.joinArcLengths
        .where((js) => js > low + 1e-6 && js < high - 1e-6)
        .toList()
      ..sort();
    // Order the joins from `a` toward `b` so the break nodes chain correctly.
    final ordered = b.s >= a.s ? joinsBetween : joinsBetween.reversed.toList();

    final boundaries = [a.s, ...ordered, b.s];
    final breakPoints = ordered.map(chord.pointAt).toList(growable: false);

    final segments = <double>[
      for (var i = 0; i < boundaries.length - 1; i++)
        (boundaries[i + 1] - boundaries[i]).abs(),
    ];

    // The end segments also carry the vertical risers to each fixture.
    segments[0] += a.riser;
    segments[segments.length - 1] += b.riser;

    return RunSplit(segmentLengths: segments, breakPoints: breakPoints);
  }

  /// Groups sticks into connected runs via union-find on coincident end-points
  /// (any angle), then orders each run into a chain.
  static List<_Run> _groupIntoRuns(List<_Stick> sticks) {
    final parent = {for (final stick in sticks) stick.uid: stick.uid};

    String find(String id) {
      var root = id;
      while (parent[root] != root) {
        root = parent[root]!;
      }
      return root;
    }

    void union(String a, String b) => parent[find(a)] = find(b);

    for (var i = 0; i < sticks.length; i++) {
      for (var j = i + 1; j < sticks.length; j++) {
        if (_sticksConnected(sticks[i], sticks[j])) {
          union(sticks[i].uid, sticks[j].uid);
        }
      }
    }

    final byRoot = <String, List<_Stick>>{};
    for (final stick in sticks) {
      byRoot.putIfAbsent(find(stick.uid), () => []).add(stick);
    }

    return byRoot.entries
        .map((entry) => _Run(entry.key, _orderChain(entry.value)))
        .toList();
  }

  static bool _sticksConnected(_Stick a, _Stick b) {
    for (final aEnd in [a.rawEnd0, a.rawEnd1]) {
      for (final bEnd in [b.rawEnd0, b.rawEnd1]) {
        if (aEnd.distanceTo(bEnd) <= kJoinCoincidenceToleranceMm) return true;
      }
    }
    return false;
  }

  /// Orders and orients a run's sticks into a single chain, walking from a free
  /// (unshared) end. Falls back to input order for loops or branches.
  static List<_Stick> _orderChain(List<_Stick> sticks) {
    if (sticks.length <= 1) return sticks;

    bool match(Vector3 a, Vector3 b) =>
        a.distanceTo(b) <= kJoinCoincidenceToleranceMm;

    bool shared(Vector3 end, _Stick self) => sticks.any((s) =>
        !identical(s, self) && (match(s.rawEnd0, end) || match(s.rawEnd1, end)));

    var startStick = sticks.first;
    var startFree = sticks.first.rawEnd0;
    for (final stick in sticks) {
      if (!shared(stick.rawEnd0, stick)) {
        startStick = stick;
        startFree = stick.rawEnd0;
        break;
      }
      if (!shared(stick.rawEnd1, stick)) {
        startStick = stick;
        startFree = stick.rawEnd1;
        break;
      }
    }

    final ordered = <_Stick>[];
    final used = <String>{};
    _Stick? current = startStick;
    var entry = startFree;

    while (current != null) {
      if (match(current.rawEnd0, entry)) {
        current.startEnd = current.rawEnd0;
        current.finishEnd = current.rawEnd1;
      } else {
        current.startEnd = current.rawEnd1;
        current.finishEnd = current.rawEnd0;
      }
      ordered.add(current);
      used.add(current.uid);

      final exit = current.finishEnd;
      entry = exit;
      current = sticks.firstWhereOrNull((s) =>
          !used.contains(s.uid) &&
          (match(s.rawEnd0, exit) || match(s.rawEnd1, exit)));
    }

    // Any sticks not reached (disconnected/branching) keep their raw order.
    for (final stick in sticks) {
      if (!used.contains(stick.uid)) {
        stick.startEnd = stick.rawEnd0;
        stick.finishEnd = stick.rawEnd1;
        ordered.add(stick);
      }
    }

    return ordered;
  }

  static double _horizontalDistance(Vector3 a, Vector3 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
