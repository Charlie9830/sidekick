import 'package:collection/collection.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

/// Builds the breakout cable graph from a complete [AppState].
///
/// Works for both the live store and the diffing comparison store, since
/// `DiffAppState` is an [AppState].
CableGraph buildCableGraphForState(AppState state) {
  return buildCableGraph(
    fixtures: state.fixtureState.fixtures,
    fixtureTypes: state.fixtureState.fixtureTypes,
    powerMultis: state.fixtureState.powerMultiOutlets,
    cables: state.fixtureState.cables,
    locations: state.fixtureState.locations,
    dataMultis: state.fixtureState.dataMultis,
    dataPatches: state.fixtureState.dataPatches,
    trusses: state.fixtureState.trusses,
    defaultPowerMulti: state.fixtureState.defaultPowerMulti,
  );
}

/// Per-location cable quantities derived from a built [CableGraph].
///
/// Counts every cable run by `(type, length)`, every adaptor those runs need,
/// and the lamp header of each multi header. Runs broken at truss joins appear
/// as their shorter segments, so the counts reflect the real cable list.
/// Shared by the breakout-cabling screen, the Excel export and diffing.
Map<String, Map<CableQtyGroup, int>> selectCableQtysByLocationId(
  CableGraph graph,
) {
  final cableEdges = graph.edges.whereType<CableEdge>();
  final items = <(String, CableQtyGroup)>[
    for (final edge in cableEdges) ...[
      (edge.locationId, CableQtyGroup(type: edge.type, length: edge.length)),
      if (edge.adaptorType case final adaptor?)
        (edge.locationId, CableQtyGroup(type: adaptor, length: 0)),
    ],
    for (final header in graph.nodes.whereType<MultiHeaderNode>())
      (
        header.locationId,
        CableQtyGroup(type: header.lampHeaderType, length: 0),
      ),
  ];

  return items
      .groupListsBy((item) => item.$1)
      .map((locationId, located) => MapEntry(locationId, _count(located)));
}

Map<CableQtyGroup, int> _count(Iterable<(String, CableQtyGroup)> items) {
  final counts = <CableQtyGroup, int>{};
  for (final (_, group) in items) {
    counts.update(group, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}
