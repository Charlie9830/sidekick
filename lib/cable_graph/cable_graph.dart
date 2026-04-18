// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';

import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

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

  Edge({
    required this.from,
    required this.to,
  });
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

class PowerMultiHeader extends Node {
  final String outletId;
  final String outletName;
  final String locationId;
  final CableType cableType;
  final double x;
  final double y;
  final double z;

  double get screenX => x;
  double get screenY => y * -1;

  PowerMultiHeader({
    required this.outletId,
    required this.outletName,
    required this.cableType,
    required this.locationId,
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

  double get screenX => x;
  double get screenY => y * -1;

  LocationNode({
    required this.locationId,
    required this.x,
    required this.y,
    required this.z,
    required super.edges,
  }) : super(id: locationId);
}

enum CableRunType {
  link,
  fixtureRun,
  homeRun,
}

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

class CableGraph {
  final Map<String, Node> _nodes;
  final Set<Edge> _edges;

  CableGraph._internal({
    required Map<String, Node> nodes,
    required Set<Edge> edges,
  })  : _edges = edges,
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

  void updateNode(String id, Node Function(Node node) update,
      {Node Function()? ifAbsent}) {
    _nodes.update(id, update, ifAbsent: ifAbsent);
  }

  Iterable<Node> walk({Node? root}) sync* {
    if (root != null) {
      assert(_nodes.containsKey(root.id),
          'Provided root parameter does not exist in graph');

      for (final edge in root.edges) {
        if (_nodes.keys.contains(edge.to)) {
          final node = _nodes[edge.to]!;
          yield node;

          for (final childNode in walk(root: node)) {
            yield childNode;
          }
        }
      }

      return;
    }

    for (final node in _nodes.values) {
      yield node;

      for (final edge in node.edges) {
        if (_nodes.keys.contains(edge.to)) {
          yield _nodes[edge.to]!;
        }
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
}) {
  final graph = CableGraph();

  // Add Locations to Graph.
  final powerMultisByLocationId = powerMultis.values
      .groupListsBy((multi) => multi.locationId)
      .map((locationId, multis) => MapEntry(locationId, multis.sorted()));

  for (final location in locations.values) {
    final firstPowerMulti = powerMultisByLocationId[location.uid]?.firstOrNull;

    if (firstPowerMulti == null) {
      continue;
    }

    final firstPowerMultiNode = graph.putIfAbsent(
        firstPowerMulti.uid,
        () => _createPowerMultiHeaderNode(
            outlet: firstPowerMulti, fixtures: fixtures, cables: cables));

    if (firstPowerMultiNode is PowerMultiHeader) {
      graph.addNode(LocationNode(
          locationId: location.uid,
          x: firstPowerMultiNode.x,
          y: firstPowerMultiNode.y,
          z: firstPowerMultiNode.z,
          edges: {
            // Add Edges to Power Multi Headers.
            if (powerMultisByLocationId.containsKey(location.uid))
              ...powerMultisByLocationId[location.uid]!.map((multi) {
                final targetPowerMultiNode = graph.putIfAbsent(
                    multi.uid,
                    () => _createPowerMultiHeaderNode(
                        outlet: multi,
                        fixtures: fixtures,
                        cables: cables)) as PowerMultiHeader;
                final eucLength = _distance(
                    firstPowerMultiNode.x,
                    firstPowerMultiNode.y,
                    firstPowerMultiNode.z,
                    targetPowerMultiNode.x,
                    targetPowerMultiNode.y,
                    targetPowerMultiNode.z);
                return multi.uid == firstPowerMulti.uid
                    ? null
                    : CableEdge(
                        from: location.uid,
                        to: multi.uid,
                        locationId: location.uid,
                        euclidianLength: eucLength,
                        runType: CableRunType.homeRun,
                        type: CableType.socapex,
                        length: roundUpToBreakpoint(eucLength, [
                          3,
                          5,
                          7.5,
                          10,
                          12.5,
                          15,
                          17.5,
                          20,
                          25,
                          30,
                          35,
                          40,
                          45,
                          50
                        ]));
              }).nonNulls
          }));
    }
  }

  // Add Fixtures to Graph.
  for (final fixture in fixtures.values) {
    graph.addNode(FixtureNode(
        id: fixture.uid,
        type: fixtureTypes[fixture.typeId]!,
        locationId: fixture.locationId,
        edges: {}));
  }

  // Add Power Cable Links to Patch.
  final fixturesByPatch = fixtures.values.groupListsBy((fix) => fix.powerPatch);
  for (final group in fixturesByPatch.values) {
    final sortedBySequence = group.sorted();
    for (int i = 0; i < sortedBySequence.length; i++) {
      final fixture = sortedBySequence[i];
      final next = sortedBySequence.elementAtOrNull(i + 1);

      final euclidianLength = next != null ? fixture.distanceTo(next) : 0.0;

      final nextEdge = next != null
          ? CableEdge(
              from: fixture.uid,
              to: next.uid,
              euclidianLength: euclidianLength,
              type: CableType.au10a,
              locationId: fixture.locationId,
              runType: CableRunType.link,
              length: roundUpToBreakpoint(euclidianLength,
                  [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]),
            )
          : null;

      graph.updateNode(
          fixture.uid,
          (existing) => (existing as FixtureNode).copyWith(
              edges: {...existing.edges, if (nextEdge != null) nextEdge}),
          ifAbsent: () => FixtureNode(
                  id: fixture.uid,
                  type: fixtureTypes[fixture.typeId]!,
                  locationId: fixture.locationId,
                  edges: {
                    if (nextEdge != null) nextEdge,
                  }));
    }
  }

  // Add Data Cables to Graph.
  final fixturesByUniverse =
      fixtures.values.groupListsBy((fix) => fix.dmxAddress.universe);
  for (final group in fixturesByUniverse.values) {
    final sortedBySequence = group.sorted();

    for (int i = 0; i < sortedBySequence.length; i++) {
      final fixture = sortedBySequence[i];
      final next = sortedBySequence.elementAtOrNull(i + 1);

      final euclidianLength = next != null ? fixture.distanceTo(next) : 0.0;

      final nextEdge = next != null
          ? CableEdge(
              from: fixture.uid,
              to: next.uid,
              euclidianLength: euclidianLength,
              locationId: fixture.locationId,
              type: CableType.dmx,
              runType: CableRunType.link,
              length: roundUpToBreakpoint(euclidianLength,
                  [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 35, 50]))
          : null;

      graph.updateNode(
          fixture.uid,
          (existing) => (existing as FixtureNode).copyWith(
              edges: {...existing.edges, if (nextEdge != null) nextEdge}),
          ifAbsent: () => FixtureNode(
                  id: fixture.uid,
                  type: fixtureTypes[fixture.typeId]!,
                  locationId: fixture.locationId,
                  edges: {
                    if (nextEdge != null) nextEdge,
                  }));
    }
  }

  return graph;
}

PowerMultiHeader _createPowerMultiHeaderNode({
  required PowerMultiOutletModel outlet,
  required Map<String, FixtureModel> fixtures,
  required Map<String, CableModel> cables,
}) {
  final headFixtures = outlet.children
      .map((child) => child.fixtureIds
          .map((id) => fixtures[id])
          .nonNulls
          .toList()
          .sorted()
          .firstOrNull)
      .nonNulls
      .toList();

  final (x, y, z) = _calculatePowerHeaderPosition(outlet, headFixtures);
  return PowerMultiHeader(
      outletId: outlet.uid,
      outletName: outlet.name,
      cableType: _determinePowerMultiCableType(outlet, cables),
      locationId: outlet.locationId,
      x: x,
      y: y + 500,
      z: z,
      edges: {
        ...headFixtures.map((headFixture) {
          final eucLength = headFixture.distanceToCoord(x, y, z);
          return CableEdge(
            from: outlet.uid,
            to: headFixture.uid,
            euclidianLength: eucLength,
            runType: CableRunType.fixtureRun,
            length: roundUpToBreakpoint(
                eucLength, [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]),
            locationId: outlet.locationId,
            type: CableType.au10a,
          );
        })
      });
}

double roundUpToBreakpoint(double value, List<double> breakpointsInMetres) {
  assert(breakpointsInMetres.isNotEmpty,
      'Breakpoints parameter must have at least 1 value');
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

CableType _determinePowerMultiCableType(
    PowerMultiOutletModel outlet, Map<String, CableModel> cables) {
  final associatedCables =
      cables.values.where((cable) => cable.outletId == outlet.uid);

  if (associatedCables.isEmpty) {
    return CableType.unknown;
  }

  if (associatedCables.length == 1) {
    return associatedCables.first.type;
  }

  final upstreamCableIds =
      associatedCables.map((cable) => cable.upstreamId).toSet();

  return associatedCables
          .lastWhereOrNull(
              (cable) => upstreamCableIds.contains(cable.uid) == false)
          ?.type ??
      CableType.unknown;
}

(double x, double y, double z) _calculatePowerHeaderPosition(
    PowerMultiOutletModel multiOutlet, List<FixtureModel> fixtures) {
  final results = fixtures
      .map((fix) => _HeaderScore(
          fixture: fix,
          reachesOtherFixtures: fixtures
              .map((candidate) =>
                  candidate == fix ? true : candidate.distanceTo(fix) <= 1000)
              .toList()))
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

  _HeaderScore({
    required this.fixture,
    required this.reachesOtherFixtures,
  });
}

double _distance(double x1, y1, z1, x2, y2, z2) {
  final dx = x1 - x2;
  final dy = y1 - y2;
  final dz = z1 - z2;
  return sqrt(dx * dx + dy * dy + dz * dz);
}
