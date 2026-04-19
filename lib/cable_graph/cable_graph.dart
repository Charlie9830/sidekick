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

class DataMultiHeaderNode extends Node {
  final String outletId;
  final String outletName;
  final String locationId;
  final double x;
  final double y;
  final double z;

  double get screenX => x;
  double get screenY =>
      (y * -1) -
      600; // 2' Offset. // TODO: This is a bit Jank. We should be calculated Screen Coords later on in the Process.

  DataMultiHeaderNode({
    required this.outletId,
    required this.outletName,
    required this.locationId,
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

  double get screenX => x;
  double get screenY =>
      (y * -1) -
      600; // 2' Offset. // TODO: This is a bit Jank. We should be calculated Screen Coords later on in the Process.

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

class PowerMultiHeaderNode extends Node {
  final String outletId;
  final String outletName;
  final String locationId;
  final CableType cableType;
  final double x;
  final double y;
  final double z;

  double get screenX => x;
  double get screenY =>
      (y * -1) -
      600; // 2' Offset. // TODO: This is a bit Jank. We should be calculated Screen Coords later on in the Process.

  PowerMultiHeaderNode({
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
  double get screenY => (y * -1) - 600; // 2' Offset.

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

class PsuedoEdge extends Edge {
  PsuedoEdge({
    required super.from,
    required super.to,
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

  void addNodes(Iterable<Node> nodes) {
    for (final node in nodes) {
      addNode(node);
    }
  }

  void updateNode(String id, Node Function(Node node) update,
      {Node Function()? ifAbsent}) {
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

  String _formatNode(Node? node) {
    return switch (node) {
      FixtureNode() => '[FixtureNode] ${node.type.name}',
      PowerMultiHeaderNode() => '[PowerMultiHeaderNode] ${node.outletName}',
      LocationNode() => '[LocationNode]',
      DataMultiHeaderNode() => '[DataMultiHeader] ${node.outletName}',
      DataPatchHeaderNode() =>
        '[DataPatchHeader] ${node.outletName} U${node.universe}',
      null => '[NULL]'
    };
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
}) {
  final graph = CableGraph();

  for (final location
      in locations.values.where((loc) => loc.isHybrid == false)) {
    final fixturesInLocation =
        fixtures.values.where((fix) => fix.locationId == location.uid);

    final (
      firstX,
      firstY,
      firstZ,
    ) = _calculateFirstFixtureLocation(fixturesInLocation);

    final fixtureNodes =
        _buildFixtureNodes(fixturesInLocation.toList(), fixtureTypes);
    graph.addNodes(fixtureNodes);

    final powerMultiNodes = _buildPowerMultiHeaderNodes(
      powerMultis.values.where((multi) => multi.locationId == location.uid),
      fixturesInLocation,
    );
    graph.addNodes(powerMultiNodes);

    final (dataMultiNodes, dataPatchNodes) = _buildDataSingleAndMultiHeaders(
        dataPatches: dataPatches.values
            .where((patch) => patch.locationId == location.uid),
        cables: cables,
        fixtures: fixturesInLocation,
        dataMultis: dataMultis);

    graph.addNodes(dataMultiNodes);
    graph.addNodes(dataPatchNodes);

    graph.addNode(LocationNode(
        locationId: location.uid,
        x: firstX,
        y: firstY,
        z: firstZ,
        edges: {
          // Create Edges to Power Multi nodes.
          ...powerMultiNodes.map((node) {
            final eucLength =
                _distance(firstX, firstY, firstZ, node.x, node.y, node.z);

            return CableEdge(
              from: location.uid,
              to: node.id,
              locationId: location.uid,
              runType: CableRunType.homeRun,
              type: node.cableType,
              euclidianLength: eucLength,
              length: _roundUpCableLength(
                  eucLength,
                  switch (node.cableType) {
                    CableType.socapex => CableLengthBreakpoints.socapex,
                    CableType.wieland6way => CableLengthBreakpoints.wieland6Way,
                    _ => throw 'Unknown Cable Type Exception',
                  }),
            );
          }),

          // Create Edges to Data Multi Nodes.
          ...dataMultiNodes
              .map((node) => PsuedoEdge(from: location.uid, to: node.id)),

          // Create Edges to Single Data Patches (That is Data patches that haven't already been connected VIA data Multi nodes)
          ...dataPatchNodes
              .where((node) => node.parentMultiOutletId.isEmpty)
              .map((node) => PsuedoEdge(from: location.uid, to: node.id)),
        }));
  }

  return graph;
}

List<FixtureNode> _buildFixtureNodes(
    List<FixtureModel> fixtures, Map<String, FixtureTypeModel> fixtureTypes) {
  final outboundPowerEdgesMap = _buildOutboundPowerLinksMap(fixtures);
  final outboundDataEdgesMap = _buildOutboundDataLinksMap(fixtures);

  return fixtures.map((fix) {
    return FixtureNode(
        id: fix.uid,
        locationId: fix.locationId,
        type: fixtureTypes[fix.typeId]!,
        edges: {
          ...outboundPowerEdgesMap[fix.uid] ?? [],
          ...outboundDataEdgesMap[fix.uid] ?? [],
        });
  }).toList();
}

Map<String, List<CableEdge>> _buildOutboundPowerLinksMap(
    Iterable<FixtureModel> fixturesInLocation) {
  final fixturesByPowerPatch = fixturesInLocation
      .groupListsBy((fix) => fix.powerPatch)
      .map((powerPatch, fixtures) => MapEntry(powerPatch, fixtures.sorted()));

  return Map<String, List<CableEdge>>.fromEntries(fixturesByPowerPatch.values
      .map((fixturesInPatch) => fixturesInPatch.mapIndexed((index, currentFix) {
            final nextFix = fixturesInPatch.elementAtOrNull(index + 1);
            if (nextFix == null) {
              return MapEntry(currentFix.uid, <CableEdge>[]);
            }

            final eucLength = currentFix.distanceTo(nextFix);
            return MapEntry(currentFix.uid, [
              CableEdge(
                  from: currentFix.uid,
                  to: nextFix.uid,
                  euclidianLength: eucLength,
                  length: _roundUpCableLength(
                      eucLength, CableLengthBreakpoints.au10A),
                  locationId: currentFix.locationId,
                  runType: CableRunType.link,
                  type: CableType.au10a // TODO: Tie to actual Cable Type.
                  )
            ]);
          }))
      .flattened);
}

Map<String, List<CableEdge>> _buildOutboundDataLinksMap(
    Iterable<FixtureModel> fixturesInLocation) {
  final fixturesByUniverse = fixturesInLocation
      .groupListsBy((fix) => fix.dmxAddress.universe)
      .map((universe, fixtures) => MapEntry(universe, fixtures.sorted()));

  return Map<String, List<CableEdge>>.fromEntries(fixturesByUniverse.values
      .map((fixturesInUniverse) => fixturesInUniverse.mapIndexed((index, fix) {
            final nextFix = fixturesInUniverse.elementAtOrNull(index + 1);
            if (nextFix == null) {
              return MapEntry(fix.uid, <CableEdge>[]);
            }

            final eucLength = fix.distanceTo(nextFix);
            return MapEntry(fix.uid, [
              CableEdge(
                  from: fix.uid,
                  to: nextFix.uid,
                  euclidianLength: eucLength,
                  length: _roundUpCableLength(
                      eucLength, CableLengthBreakpoints.dmx),
                  locationId: fix.locationId,
                  runType: CableRunType.link,
                  type: CableType.dmx // TODO: Tie to actual Cable Type.
                  )
            ]);
          }))
      .flattened);
}

List<PowerMultiHeaderNode> _buildPowerMultiHeaderNodes(
    Iterable<PowerMultiOutletModel> outlets, Iterable<FixtureModel> fixtures) {
  return outlets.map((outlet) {
    final downstreamFixtures =
        fixtures.where((fix) => fix.powerMultiOutletId == outlet.uid).toList();

    final (x, y, z) = _calculatePowerHeaderPosition(
      outlet,
      downstreamFixtures,
    );

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
          ..._extractFirstFixturesInPower(outlet.uid, downstreamFixtures)
              .map((fix) {
            final eucLength = fix.distanceToCoord(x, y, z);
            return CableEdge(
              from: outlet.uid,
              to: fix.uid,
              euclidianLength: eucLength,
              runType: CableRunType.fixtureRun,
              length: _roundUpCableLength(
                  eucLength,
                  CableLengthBreakpoints
                      .au10A), // TODO: Tie to actual Cable Type.
              locationId: outlet.locationId,
              type: CableType.au10a, // TODO: Tie to actual Cable Type.
            );
          })
        });
  }).toList();
}

(List<DataMultiHeaderNode>, List<DataPatchHeaderNode>)
    _buildDataSingleAndMultiHeaders({
  required Iterable<DataPatchModel> dataPatches,
  required Map<String, CableModel> cables,
  required Iterable<FixtureModel> fixtures,
  required Map<String, DataMultiModel> dataMultis,
}) {
  final cablesByOutletId =
      cables.values.groupListsBy((cable) => cable.outletId);

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
    final eucLength =
        firstFixture?.distanceToCoord(firstX, firstY, firstZ) ?? 0;
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
              euclidianLength: eucLength,
              length:
                  _roundUpCableLength(eucLength, CableLengthBreakpoints.dmx),
              from: outlet.uid,
              to: firstFixture.uid,
              locationId: outlet.locationId,
              runType: CableRunType.fixtureRun,
              type: CableType.dmx,
            )
        });
  }).toList();

  final patchHeaderNodesByParentMultiOutletId =
      dataPatchNodes.groupListsBy((node) => lookupParentMultiId(node.id));

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
            .toSet());

    multiHeaderNodes.add(multiNode);
  }

  return (multiHeaderNodes, dataPatchNodes);
}

(double x, double y, double z) _calculateFirstFixtureLocation(
    Iterable<FixtureModel> fixtures) {
  final sorted = fixtures.sorted();

  if (sorted.isNotEmpty) {
    return (sorted.first.x, sorted.first.y, sorted.first.z);
  }

  return (0, 0, 0);
}

double _roundUpCableLength(double value, List<double> breakpointsInMetres) {
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

List<FixtureModel> _extractFirstFixturesInPower(
    String outletId, List<FixtureModel> fixtures) {
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
    Iterable<FixtureModel> fixtures) {
  final sorted = fixtures.sorted();
  return Map<int, FixtureModel>.fromEntries(sorted
      .groupListsBy((fix) => fix.dmxAddress.universe)
      .entries
      .map((entry) => MapEntry(entry.key, entry.value.first)));
}

CableType _calculatePowerMultiCableType(
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

(double x, double y, double z) _calculateDataHeaderPosition(
    DataMultiModel multiOutlet, List<FixtureModel> fixtures) {
  if (fixtures.isEmpty) {
    return (0, 0, 0);
  }

  final first = fixtures.first;

  return (first.x, first.y, first.z);
}

(double x, double y, double z) _calculatePowerHeaderPosition(
    PowerMultiOutletModel multiOutlet, List<FixtureModel> fixtures) {
  if (fixtures.isEmpty) {
    return (0, 0, 0);
  }
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
