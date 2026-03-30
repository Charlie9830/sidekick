import 'package:collection/collection.dart';
import 'package:directed_graph/directed_graph.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';

/// Generic builder to create a daisy-chained graph based on a grouping criteria.
WeightedDirectedGraph<FixtureVertex, EdgeData> _buildCablingGraph({
  required List<FixtureModel> fixtures,
  required dynamic Function(FixtureModel) groupBy,
  required int Function(FixtureModel a, FixtureModel b) comparator,
  required CableType cableType,
}) {
  final groups = fixtures.groupListsBy(groupBy);
  final edges = <FixtureVertex, Map<FixtureVertex, EdgeData>>{};

  for (final group in groups.values) {
    // Sort the group by sequence to ensure the daisy chain order is correct.
    final sortedGroup = group.sorted((a, b) => comparator(a, b));

    for (int i = 0; i < sortedGroup.length; i++) {
      final current = FixtureVertex(fixture: sortedGroup[i]);

      // Initialize the entry to ensure leaf nodes (end of chain) are included in the graph data.
      edges.putIfAbsent(current, () => {});

      if (i < sortedGroup.length - 1) {
        final next = FixtureVertex(fixture: sortedGroup[i + 1]);
        edges[current]!.addAll({
          next: EdgeData(
              cableType: cableType,
              cableLength:
                  current.fixture.distanceTo(next.fixture).ceilToDouble(),
              directLength: current.fixture.distanceTo(next.fixture))
        });
      }
    }
  }

  return WeightedDirectedGraph<FixtureVertex, EdgeData>(
      summation: (left, right) => EdgeData(
            cableType: CableType.unknown,
            cableLength: 0,
            directLength: 0,
          ),
      zero: EdgeData(
        cableType: CableType.unknown,
        cableLength: 0,
        directLength: 0,
      ),
      edges);
}

/// Builds a graph representing Power cabling daisy chains, grouped by [powerPatch].
WeightedDirectedGraph<FixtureVertex, EdgeData> buildPowerCableGraph(
    {required List<FixtureModel> fixtures}) {
  return _buildCablingGraph(
    fixtures: fixtures,
    groupBy: (fixture) => fixture.powerPatch,
    comparator: (a, b) => a.sequence - b.sequence,
    cableType: CableType.au10a,
  );
}

/// Builds a graph representing Data cabling daisy chains, grouped by DMX Universe.
WeightedDirectedGraph<FixtureVertex, EdgeData> buildDataCableGraph(
    {required List<FixtureModel> fixtures}) {
  return _buildCablingGraph(
    fixtures: fixtures,
    groupBy: (fixture) => fixture.dmxAddress.universe,
    comparator: (a, b) => a.sequence - b.sequence,
    cableType: CableType.dmx,
  );
}

class FixtureVertex implements Comparable {
  final FixtureModel fixture;

  FixtureVertex({
    required this.fixture,
  });

  @override
  bool operator ==(Object other) {
    return other is FixtureVertex && other.fixture.uid == fixture.uid;
  }

  @override
  int get hashCode => fixture.uid.hashCode;

  @override
  String toString() {
    return '#${fixture.fid.toString()}';
  }

  @override
  int compareTo(other) {
    if (other is! FixtureVertex) {
      throw "Cant compare";
    }

    return fixture.sequence - other.fixture.sequence;
  }
}

class EdgeData implements Comparable {
  final CableType cableType;
  final double directLength;
  final double cableLength;

  EdgeData({
    required this.cableType,
    required this.directLength,
    required this.cableLength,
  });

  @override
  int compareTo(other) {
    return other is EdgeData ? (other.cableLength - cableLength).floor() : 0;
  }
}
