// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';

import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/cable_graph/truss_geometry.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

sealed class Node {
  final String id;
  final Set<Edge> edges;

  Node({required this.edges, required this.id});

  @override
  bool operator ==(Object other) {
    return other is Node && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

sealed class Edge {
  final String from;
  final String to;

  Edge({required this.from, required this.to});
}

class FixtureNode extends Node {
  final FixtureTypeModel type;
  final String locationId;

  FixtureNode({
    required super.id,
    required this.type,
    required this.locationId,
    required super.edges,
  });

  FixtureNode copyWith({
    FixtureTypeModel? type,
    String? locationId,
    Set<Edge>? edges,
  }) {
    return FixtureNode(
      id: id,
      type: type ?? this.type,
      locationId: locationId ?? this.locationId,
      edges: edges ?? this.edges,
    );
  }
}

sealed class MultiHeaderNode extends Node {
  final String locationId;

  MultiHeaderNode({
    required super.id,
    required super.edges,
    required this.locationId,
  });
}

class DataMultiHeaderNode extends MultiHeaderNode {
  final String outletId;
  final String outletName;
  final double x;
  final double y;
  final double z;

  DataMultiHeaderNode({
    required this.outletId,
    required this.outletName,
    required super.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  }) : super(id: outletId);
}

class DataPatchHeaderNode extends Node {
  final String outletId;
  final String outletName;
  final String parentMultiOutletId;
  final int universe;
  final String locationId;
  final double x;
  final double y;
  final double z;

  DataPatchHeaderNode({
    required this.outletId,
    required this.outletName,
    required this.parentMultiOutletId,
    required this.universe,
    required this.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  }) : super(id: outletId);
}

class PowerMultiHeaderNode extends MultiHeaderNode {
  final String outletId;
  final String outletName;
  final CableType cableType;
  final double x;
  final double y;
  final double z;

  PowerMultiHeaderNode({
    required this.outletId,
    required this.outletName,
    required this.cableType,
    required super.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  }) : super(id: outletId);
}

class LocationNode extends Node {
  final String locationId;
  final double x;
  final double y;
  final double z;

  LocationNode({
    required this.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  }) : super(id: locationId);
}

/// A point where a cable is broken because it crosses a truss join.
///
/// Inserted between two endpoints when a run spans one or more joins, so the run
/// is represented as a chain of shorter [CableEdge]s.
class TrussBreakNode extends Node {
  final String locationId;
  final double x;
  final double y;
  final double z;

  TrussBreakNode({
    required super.id,
    required this.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  });
}

enum CableRunType { link, fixtureRun, homeRun }

class CableEdge extends Edge {
  final double euclidianLength;
  final double length;
  final CableType type;
  final String locationId;
  final CableRunType runType;

  CableEdge({
    required super.from,
    required super.to,
    required this.euclidianLength,
    required this.length,
    required this.type,
    required this.locationId,
    required this.runType,
  });
}

class PsuedoEdge extends Edge {
  PsuedoEdge({required super.from, required super.to});
}

class CableGraph {
  final Map<String, Node> _nodes;
  final Set<Edge> _edges;

  CableGraph._internal({
    required Map<String, Node> nodes,
    required Set<Edge> edges,
  }) : _edges = edges,
       _nodes = nodes;

  factory CableGraph() {
    return CableGraph._internal(nodes: {}, edges: {});
  }

  Iterable<Node> get nodes => _nodes.values;
  Iterable<Edge> get edges => _edges;

  Node? getNode(String id) {
    return _nodes[id];
  }

  Node putIfAbsent(String id, Node Function() ifAbsent) {
    return _nodes.putIfAbsent(id, ifAbsent);
  }

  Node addNode(Node node) {
    _nodes[node.id] = node;

    for (final edge in node.edges) {
      if (_edges.contains(edge) == false) {
        _edges.add(edge);
      }
    }

    return node;
  }

  void addNodes(Iterable<Node> nodes) {
    for (final node in nodes) {
      addNode(node);
    }
  }

  void updateNode(
    String id,
    Node Function(Node node) update, {
    Node Function()? ifAbsent,
  }) {
    _nodes.update(id, update, ifAbsent: ifAbsent);
  }

  Iterable<Node> walk(Node root) sync* {
    final visited = <String>{};
    final stack = <Node>[root];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();

      if (visited.contains(node.id) == false) {
        visited.add(node.id);
        yield node; // Yield the Current node

        // Add it's neighbours to the Stack.
        stack.addAll(node.edges.map((edge) => _nodes[edge.to]).nonNulls);
      }
    }
  }
}

CableGraph buildCableGraph({
  required Map<String, FixtureModel> fixtures,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, CableModel> cables,
  required Map<String, LocationModel> locations,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  Map<String, TrussModel> trusses = const {},
}) {
  final graph = CableGraph();

  final truss = _TrussContext.build(trusses: trusses, fixtures: fixtures);

  for (final location in locations.values.where(
    (loc) => loc.isHybrid == false,
  )) {
    final fixturesInLocation = fixtures.values.where(
      (fix) => fix.locationId == location.uid,
    );

    final (firstX, firstY, firstZ) = _calculateFirstFixtureLocation(
      fixturesInLocation,
    );

    final fixtureNodes = _buildFixtureNodes(
      fixturesInLocation.toList(),
      fixtureTypes,
      graph,
      truss,
      breakAtTrussJoins: location.breakAtTrussJoins,
    );
    graph.addNodes(fixtureNodes);

    final powerMultiNodes = _buildPowerMultiHeaderNodes(
      powerMultis.values.where((multi) => multi.locationId == location.uid),
      fixturesInLocation,
      truss,
    );
    graph.addNodes(powerMultiNodes);

    final (dataMultiNodes, dataPatchNodes) = _buildDataSingleAndMultiHeaders(
      dataPatches: dataPatches.values.where(
        (patch) => patch.locationId == location.uid,
      ),
      cables: cables,
      fixtures: fixturesInLocation,
      dataMultis: dataMultis,
      truss: truss,
    );

    graph.addNodes(dataMultiNodes);
    graph.addNodes(dataPatchNodes);

    graph.addNode(
      LocationNode(
        locationId: location.uid,
        x: firstX,
        y: firstY,
        z: firstZ,
        edges: {
          // Create Edges to Power Multi nodes.
          ...powerMultiNodes.map((node) {
            final eucLength = _distance(
              firstX,
              firstY,
              firstZ,
              node.x,
              node.y,
              node.z,
            );

            return CableEdge(
              from: location.uid,
              to: node.id,
              locationId: location.uid,
              runType: CableRunType.homeRun,
              type: node.cableType,
              euclidianLength: eucLength,
              length: _roundUpCableLength(eucLength, switch (node.cableType) {
                CableType.socapex => CableLengthBreakpoints.socapex,
                CableType.wieland6way => CableLengthBreakpoints.wieland6Way,
                _ => throw 'Unknown Cable Type Exception',
              }),
            );
          }),

          // Create Edges to Data Multi Nodes.
          ...dataMultiNodes.map(
            (node) => PsuedoEdge(from: location.uid, to: node.id),
          ),

          // Create Edges to Single Data Patches (That is Data patches that haven't already been connected VIA data Multi nodes)
          ...dataPatchNodes
              .where((node) => node.parentMultiOutletId.isEmpty)
              .map((node) => PsuedoEdge(from: location.uid, to: node.id)),
        },
      ),
    );
  }

  return graph;
}

List<FixtureNode> _buildFixtureNodes(
  List<FixtureModel> fixtures,
  Map<String, FixtureTypeModel> fixtureTypes,
  CableGraph graph,
  _TrussContext truss, {
  required bool breakAtTrussJoins,
}) {
  final outboundPowerEdgesMap = _buildOutboundPowerLinksMap(
    fixtures,
    graph,
    truss,
    breakAtTrussJoins: breakAtTrussJoins,
  );
  final outboundDataEdgesMap = _buildOutboundDataLinksMap(
    fixtures,
    graph,
    truss,
    breakAtTrussJoins: breakAtTrussJoins,
  );

  return fixtures.map((fix) {
    return FixtureNode(
      id: fix.uid,
      locationId: fix.locationId,
      type: fixtureTypes[fix.typeId]!,
      edges: {
        ...outboundPowerEdgesMap[fix.uid] ?? [],
        ...outboundDataEdgesMap[fix.uid] ?? [],
      },
    );
  }).toList();
}

Map<String, List<CableEdge>> _buildOutboundPowerLinksMap(
  Iterable<FixtureModel> fixturesInLocation,
  CableGraph graph,
  _TrussContext truss, {
  required bool breakAtTrussJoins,
}) {
  final fixturesByPowerPatch = fixturesInLocation
      .groupListsBy((fix) => fix.powerPatch)
      .map((powerPatch, fixtures) => MapEntry(powerPatch, fixtures.sorted()));

  return Map<String, List<CableEdge>>.fromEntries(
    fixturesByPowerPatch.values
        .map(
          (fixturesInPatch) => fixturesInPatch.mapIndexed((index, currentFix) {
            final nextFix = fixturesInPatch.elementAtOrNull(index + 1);
            if (nextFix == null) {
              return MapEntry(currentFix.uid, <CableEdge>[]);
            }

            return MapEntry(
              currentFix.uid,
              _buildRunEdges(
                graph: graph,
                truss: truss,
                from: currentFix,
                to: nextFix,
                type: CableType.au10a, // TODO: Tie to actual Cable Type.
                runType: CableRunType.link,
                locationId: currentFix.locationId,
                breakpoints: CableLengthBreakpoints.au10A,
                breakAtTrussJoins: breakAtTrussJoins,
              ),
            );
          }),
        )
        .flattened,
  );
}

Map<String, List<CableEdge>> _buildOutboundDataLinksMap(
  Iterable<FixtureModel> fixturesInLocation,
  CableGraph graph,
  _TrussContext truss, {
  required bool breakAtTrussJoins,
}) {
  final fixturesByUniverse = fixturesInLocation
      .groupListsBy((fix) => fix.dmxAddress.universe)
      .map((universe, fixtures) => MapEntry(universe, fixtures.sorted()));

  return Map<String, List<CableEdge>>.fromEntries(
    fixturesByUniverse.values
        .map(
          (fixturesInUniverse) => fixturesInUniverse.mapIndexed((index, fix) {
            final nextFix = fixturesInUniverse.elementAtOrNull(index + 1);
            if (nextFix == null) {
              return MapEntry(fix.uid, <CableEdge>[]);
            }

            return MapEntry(
              fix.uid,
              _buildRunEdges(
                graph: graph,
                truss: truss,
                from: fix,
                to: nextFix,
                type: CableType.dmx, // TODO: Tie to actual Cable Type.
                runType: CableRunType.link,
                locationId: fix.locationId,
                breakpoints: CableLengthBreakpoints.dmx,
                breakAtTrussJoins: breakAtTrussJoins,
              ),
            );
          }),
        )
        .flattened,
  );
}

/// Bundles the truss topology with the fixture-to-stick assignments.
class _TrussContext {
  final TrussGeometry geometry;
  final Map<String, TrussAssignment> assignments;

  _TrussContext({required this.geometry, required this.assignments});

  factory _TrussContext.build({
    required Map<String, TrussModel> trusses,
    required Map<String, FixtureModel> fixtures,
  }) {
    final geometry = TrussGeometry.fromTrusses(trusses.values);
    final assignments = geometry.isEmpty
        ? <String, TrussAssignment>{}
        : geometry.assignFixtures(
            fixtures.values.map(
              (fix) => (uid: fix.uid, x: fix.x, y: fix.y, z: fix.z),
            ),
          );

    return _TrussContext(geometry: geometry, assignments: assignments);
  }

  /// Length of a home run from a header at [from] to [fixture].
  ///
  /// Trussed fixtures follow their run's chord (entering at the nearest point);
  /// floor fixtures fall back to a straight line plus a [kFloorRiserMm] riser.
  double homeRunLength(Vector3 from, FixtureModel fixture) {
    final assignment = assignments[fixture.uid];
    if (assignment != null) {
      final length = geometry.homeRunLength(from: from, assignment: assignment);
      if (length != null) return length;
    }
    return from.distanceTo(Vector3(fixture.x, fixture.y, fixture.z)) +
        kFloorRiserMm;
  }
}

/// Builds the cable edge(s) for a fixture-to-fixture run, splitting at any truss
/// joins the run crosses.
///
/// Break nodes for each crossing are added to [graph] and own the downstream
/// segments; the returned list holds only the edge(s) the source fixture owns
/// (so the caller can attach them to the source's edge set). A run that crosses
/// no joins (or whose endpoints aren't both on a truss) yields a single edge,
/// preserving the previous behaviour.
///
/// When [breakAtTrussJoins] is false the run is never split: the whole run is
/// returned as a single edge whose length follows the run's chord across every
/// join it would otherwise break at.
List<CableEdge> _buildRunEdges({
  required CableGraph graph,
  required _TrussContext truss,
  required FixtureModel from,
  required FixtureModel to,
  required CableType type,
  required CableRunType runType,
  required String locationId,
  required List<double> breakpoints,
  required bool breakAtTrussJoins,
}) {
  final split = truss.geometry.splitRun(
    from: Vector3(from.x, from.y, from.z),
    to: Vector3(to.x, to.y, to.z),
    fromAssignment: truss.assignments[from.uid],
    toAssignment: truss.assignments[to.uid],
  );

  if (!breakAtTrussJoins || !split.hasBreaks) {
    // A single edge spanning the whole run. The chord length is the sum of the
    // segment lengths (which is just the one segment when there are no breaks).
    final length = split.segmentLengths.reduce((a, b) => a + b);
    return [
      CableEdge(
        from: from.uid,
        to: to.uid,
        euclidianLength: length,
        length: _roundUpCableLength(length, breakpoints),
        locationId: locationId,
        runType: runType,
        type: type,
      ),
    ];
  }

  // Assemble the chain: from -> break_0 -> ... -> break_n -> to. The cable type
  // is part of the break node id so that a power link and a data link between
  // the same fixture pair don't collide on shared break nodes.
  final ids = <String>[
    from.uid,
    for (var i = 0; i < split.breakPoints.length; i++)
      '${from.uid}~${type.name}brk$i~${to.uid}',
    to.uid,
  ];

  final edges = <CableEdge>[
    for (var i = 0; i < ids.length - 1; i++)
      CableEdge(
        from: ids[i],
        to: ids[i + 1],
        euclidianLength: split.segmentLengths[i],
        length: _roundUpCableLength(split.segmentLengths[i], breakpoints),
        locationId: locationId,
        runType: runType,
        type: type,
      ),
  ];

  // Each interior break node owns the edge leaving it toward the next point.
  for (var i = 0; i < split.breakPoints.length; i++) {
    final point = split.breakPoints[i];
    graph.addNode(
      TrussBreakNode(
        id: ids[i + 1],
        locationId: locationId,
        x: point.x,
        y: point.y,
        z: point.z,
        edges: {edges[i + 1]},
      ),
    );
  }

  // The source fixture only owns the first segment.
  return [edges.first];
}

List<PowerMultiHeaderNode> _buildPowerMultiHeaderNodes(
  Iterable<PowerMultiOutletModel> outlets,
  Iterable<FixtureModel> fixtures,
  _TrussContext truss,
) {
  return outlets.map((outlet) {
    final downstreamFixtures = fixtures
        .where((fix) => fix.powerMultiOutletId == outlet.uid)
        .toList();

    final (x, y, z) = _calculatePowerHeaderPosition(outlet, downstreamFixtures);

    return PowerMultiHeaderNode(
      outletId: outlet.uid,
      outletName: outlet.name,
      cableType: CableType.socapex, // TODO: Tie to actual Cable type
      locationId: outlet.locationId,
      x: x,
      y: y,
      z: z,
      edges: {
        // Create edges representing the Fixture Home Runs. That is the cables that go from the Header to the first (or only) fixture of each circuit.
        ..._extractFirstFixturesInPower(outlet.uid, downstreamFixtures).map((
          fix,
        ) {
          final runLength = truss.homeRunLength(Vector3(x, y, z), fix);
          return CableEdge(
            from: outlet.uid,
            to: fix.uid,
            euclidianLength: runLength,
            runType: CableRunType.fixtureRun,
            length: _roundUpCableLength(
              runLength,
              CableLengthBreakpoints.au10A,
            ), // TODO: Tie to actual Cable Type.
            locationId: outlet.locationId,
            type: CableType.au10a, // TODO: Tie to actual Cable Type.
          );
        }),
      },
    );
  }).toList();
}

(List<DataMultiHeaderNode>, List<DataPatchHeaderNode>)
_buildDataSingleAndMultiHeaders({
  required Iterable<DataPatchModel> dataPatches,
  required Map<String, CableModel> cables,
  required Iterable<FixtureModel> fixtures,
  required Map<String, DataMultiModel> dataMultis,
  required _TrussContext truss,
}) {
  final cablesByOutletId = cables.values.groupListsBy(
    (cable) => cable.outletId,
  );

  // Helper function to simplify multi step lookups.
  String lookupParentMultiId(String patchOutletId) {
    final correspondingCable = cablesByOutletId[patchOutletId]?.firstOrNull;

    if (correspondingCable == null ||
        correspondingCable.parentMultiId.isEmpty) {
      return '';
    }

    final parentCable = cables[correspondingCable.parentMultiId];

    return parentCable?.outletId ?? '';
  }

  final (firstX, firstY, firstZ) = _calculateFirstFixtureLocation(fixtures);
  final universeLeaders = _mapFirstFixturesInUniverses(fixtures);

  final dataPatchNodes = dataPatches.map((outlet) {
    final firstFixture = universeLeaders[outlet.universe];
    final runLength = firstFixture == null
        ? 0.0
        : truss.homeRunLength(Vector3(firstX, firstY, firstZ), firstFixture);
    return DataPatchHeaderNode(
      outletId: outlet.uid,
      outletName: outlet.name,
      universe: outlet.universe,
      parentMultiOutletId: lookupParentMultiId(outlet.uid),
      locationId: outlet.locationId,
      x: firstX,
      y: firstY,
      z: firstZ,
      edges: {
        if (firstFixture != null)
          CableEdge(
            euclidianLength: runLength,
            length: _roundUpCableLength(runLength, CableLengthBreakpoints.dmx),
            from: outlet.uid,
            to: firstFixture.uid,
            locationId: outlet.locationId,
            runType: CableRunType.fixtureRun,
            type: CableType.dmx,
          ),
      },
    );
  }).toList();

  final patchHeaderNodesByParentMultiOutletId = dataPatchNodes.groupListsBy(
    (node) => lookupParentMultiId(node.id),
  );

  final List<DataMultiHeaderNode> multiHeaderNodes = [];

  for (final entry in patchHeaderNodesByParentMultiOutletId.entries) {
    final multiOutletId = entry.key;
    final childPatchNodes = entry.value;
    final dataMulti = dataMultis[multiOutletId];

    if (multiOutletId.isEmpty || dataMulti == null) {
      continue;
    }

    final multiNode = DataMultiHeaderNode(
      outletId: multiOutletId,
      outletName: dataMulti.name,
      locationId: dataMulti.locationId,
      x: firstX,
      y: firstY,
      z: firstZ,
      edges: childPatchNodes
          .map((node) => PsuedoEdge(from: multiOutletId, to: node.id))
          .toSet(),
    );

    multiHeaderNodes.add(multiNode);
  }

  return (multiHeaderNodes, dataPatchNodes);
}

(double x, double y, double z) _calculateFirstFixtureLocation(
  Iterable<FixtureModel> fixtures,
) {
  final sorted = fixtures.sorted();

  if (sorted.isNotEmpty) {
    return (sorted.first.x, sorted.first.y, sorted.first.z);
  }

  return (0, 0, 0);
}

double _roundUpCableLength(double value, List<double> breakpointsInMetres) {
  assert(
    breakpointsInMetres.isNotEmpty,
    'Breakpoints parameter must have at least 1 value',
  );
  final coercedValue = (value.ceilToDouble() * 0.001).clamp(0, double.infinity);

  if (coercedValue <= breakpointsInMetres.first) {
    return breakpointsInMetres.first;
  }

  if (coercedValue >= breakpointsInMetres.last) {
    return breakpointsInMetres.last;
  }

  for (int i = 0; i < breakpointsInMetres.length; i++) {
    final current = breakpointsInMetres[i];
    final next = breakpointsInMetres.elementAtOrNull(i + 1);

    if (next == null) {
      return current;
    }

    if (coercedValue == current) {
      return current;
    }

    if (coercedValue > current && coercedValue <= next) {
      return next;
    }
  }

  return breakpointsInMetres.last;
}

List<FixtureModel> _extractFirstFixturesInPower(
  String outletId,
  List<FixtureModel> fixtures,
) {
  final sorted = fixtures.sorted();
  return sorted
      .groupListsBy((fix) => fix.powerPatch)
      .values
      .map((fixtures) {
        return fixtures.firstOrNull;
      })
      .nonNulls
      .toList();
}

Map<int, FixtureModel> _mapFirstFixturesInUniverses(
  Iterable<FixtureModel> fixtures,
) {
  final sorted = fixtures.sorted();
  return Map<int, FixtureModel>.fromEntries(
    sorted
        .groupListsBy((fix) => fix.dmxAddress.universe)
        .entries
        .map((entry) => MapEntry(entry.key, entry.value.first)),
  );
}

(double x, double y, double z) _calculatePowerHeaderPosition(
  PowerMultiOutletModel multiOutlet,
  List<FixtureModel> fixtures,
) {
  if (fixtures.isEmpty) {
    return (0, 0, 0);
  }
  final results = fixtures
      .map(
        (fix) => _HeaderScore(
          fixture: fix,
          reachesOtherFixtures: fixtures
              .map(
                (candidate) =>
                    candidate == fix ? true : candidate.distanceTo(fix) <= 1000,
              )
              .toList(),
        ),
      )
      .toList();

  _HeaderScore best = results.first;
  for (final result in results) {
    if (result.score > best.score) {
      best = result;
    }
  }

  return (best.fixture.x, best.fixture.y, best.fixture.z);
}

class _HeaderScore {
  final FixtureModel fixture;
  final List<bool> reachesOtherFixtures;
  int get score => reachesOtherFixtures.where((value) => value == true).length;

  _HeaderScore({required this.fixture, required this.reachesOtherFixtures});
}

double _distance(double x1, y1, z1, x2, y2, z2) {
  final dx = x1 - x2;
  final dy = y1 - y2;
  final dz = z1 - z2;
  return sqrt(dx * dx + dy * dy + dz * dz);
}
