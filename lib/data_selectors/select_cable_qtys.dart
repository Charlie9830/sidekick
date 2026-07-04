import 'package:collection/collection.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/redux/models/cable_model.dart';
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
  );
}

/// Per-location cable quantities derived from a built [CableGraph].
///
/// Combines the individual cable runs (counted by `(type, length)`) with the
/// lamp-header quantities implied by each multi header. Runs broken at truss
/// joins appear as their shorter segments, so the counts reflect the real cable
/// list. Shared by the breakout-cabling screen, the Excel export and diffing.
Map<String, Map<CableQtyGroup, int>> selectCableQtysByLocationId(
    CableGraph graph) {
  final cablesByLocationId = _cableQtysByLocationId(graph);
  final headersByLocationId = _headerQtysByLocationId(graph);

  final result = <String, Map<CableQtyGroup, int>>{};
  final locationIds = {
    ...cablesByLocationId.keys,
    ...headersByLocationId.keys,
  };

  for (final locationId in locationIds) {
    result[locationId] = {
      ...?cablesByLocationId[locationId],
      ...?headersByLocationId[locationId],
    };
  }

  return result;
}

Map<String, Map<CableQtyGroup, int>> _cableQtysByLocationId(CableGraph graph) {
  return Map<String, Map<CableQtyGroup, int>>.fromEntries(graph.edges
      .whereType<CableEdge>()
      .groupListsBy((edge) => edge.locationId)
      .entries
      .map((entry) {
    final groups = entry.value
        .map((edge) => CableQtyGroup(type: edge.type, length: edge.length));

    final map = <CableQtyGroup, int>{};
    for (final group in groups) {
      map.update(group, (count) => count + 1, ifAbsent: () => 1);
    }

    return MapEntry(entry.key, map);
  }));
}

Map<String, Map<CableQtyGroup, int>> _headerQtysByLocationId(CableGraph graph) {
  return Map<String, Map<CableQtyGroup, int>>.fromEntries(graph.nodes
      .whereType<MultiHeaderNode>()
      .groupListsBy((node) => node.locationId)
      .entries
      .map((entry) {
    final groups = entry.value.map((node) => CableQtyGroup(
        type: switch (node) {
          DataMultiHeaderNode() => CableType.sneakLampHeader,
          PowerMultiHeaderNode() => switch (node.cableType) {
              CableType.socapex => node.edges
                      .whereType<CableEdge>()
                      .every((edge) => edge.type == CableType.true1)
                  ? CableType.socapexToTrue1LampHeader
                  : CableType.socapexToAu10ALampHeader,
              CableType.wieland6way => CableType.wieland6WayLampHeader,
              _ => throw UnimplementedError(),
            }
        },
        length: 0));

    final map = <CableQtyGroup, int>{};
    for (final group in groups) {
      map.update(group, (count) => count + 1, ifAbsent: () => 1);
    }

    return MapEntry(entry.key, map);
  }));
}
