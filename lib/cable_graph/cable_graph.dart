import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

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
}

class PowerMultiHeader extends Node {
  final String outletId;
  final String outletName;
  final String locationId;
  final CableType cableType;

  PowerMultiHeader({
    required this.outletId,
    required this.outletName,
    required this.cableType,
    required this.locationId,
    required super.edges,
  }) : super(id: outletId);
}

class CableEdge extends Edge {
  final double euclidianLength;
  final double length;
  final CableType type;
  final String locationId;

  CableEdge({
    required super.from,
    required super.to,
    required this.euclidianLength,
    required this.length,
    required this.type,
    required this.locationId,
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

  void addNode(Node node) {
    final n = _nodes.putIfAbsent(node.id, () => node);

    for (final edge in n.edges) {
      if (_edges.contains(edge) == false) {
        _edges.add(edge);
      }
    }
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
          yield _nodes[edge.to]!;
        }
      }
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
}) {
  final graph = CableGraph();

  // Add Power Cables to Graph.
  final fixturesByPatch = fixtures.values.groupListsBy((fix) => fix.powerPatch);
  for (final group in fixturesByPatch.values) {
    final sortedBySequence = group.sorted();
    for (int i = 0; i < sortedBySequence.length; i++) {
      final fixture = sortedBySequence[i];
      final next = sortedBySequence.elementAtOrNull(i + 1);

      final euclidianLength = next != null ? fixture.distanceTo(next) : 0.0;

      graph.addNode(
        FixtureNode(
          id: fixture.uid,
          type: fixtureTypes[fixture.typeId]!,
          locationId: fixture.locationId,
          edges: {
            if (next != null)
              CableEdge(
                from: fixture.uid,
                to: next.uid,
                euclidianLength: euclidianLength,
                type: CableType.au10a,
                locationId: fixture.locationId,
                length: roundUpToBreakpoint(euclidianLength,
                    [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]),
              )
          },
        ),
      );
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

      final edge = next != null
          ? CableEdge(
              from: fixture.uid,
              to: next.uid,
              euclidianLength: euclidianLength,
              locationId: fixture.locationId,
              type: CableType.dmx,
              length: roundUpToBreakpoint(euclidianLength,
                  [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 35, 50]))
          : null;

      graph.updateNode(fixture.uid, (existing) {
        if (edge != null) {
          existing.edges.add(edge);
        }
        return existing;
      },
          ifAbsent: () => FixtureNode(
                id: fixture.uid,
                edges: {if (edge != null) edge},
                locationId: fixture.locationId,
                type: fixtureTypes[fixture.typeId]!,
              ));

      graph.addNode(
        FixtureNode(
          id: fixture.uid,
          type: fixtureTypes[fixture.typeId]!,
          locationId: fixture.locationId,
          edges: {
            CableEdge(
              from: fixture.uid,
              to: next?.uid ?? '',
              locationId: fixture.locationId,
              euclidianLength: euclidianLength,
              type: CableType.au10a,
              length: roundUpToBreakpoint(euclidianLength,
                  [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]),
            )
          },
        ),
      );
    }
  }

  // Add Power Multi Headers to Graph.
  for (final entry in fixturesByPatch.entries) {
    final patch = entry.key;
    final fixtures = entry.value.sorted();
  }

  return graph;
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
