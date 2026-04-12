import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/breakout_cabling/breakout_cabling.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class BreakoutCablingContainer extends StatelessWidget {
  const BreakoutCablingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, BreakoutCablingViewModel>(
      builder: (context, viewModel) {
        return BreakoutCabling(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        final cableGraph = _selectCableGraph(store);
        final fixtureVms = _selectFixtureVms(store);
        final locationFixtures = _selectLocationFixtures(
            fixtureVms, store.state.navstate.selectedBreakoutCablingLocationId);

        return BreakoutCablingViewModel(
            selectedLocationId:
                store.state.navstate.selectedBreakoutCablingLocationId,
            locationVms: _selectLocations(store),
            locationFixtureVms: locationFixtures,
            fixtureMap: store.state.fixtureState.fixtures,
            cableViewVm: _selectCableViewVm(
              graph: cableGraph,
              fixtureVms: fixtureVms,
              selectedLocationId:
                  store.state.navstate.selectedBreakoutCablingLocationId,
            ));
      },
    );
  }
}

CableViewViewModel _selectCableViewVm({
  required CableGraph graph,
  required Map<String, FixtureViewModel> fixtureVms,
  required String selectedLocationId,
}) {
  final mappedFixtureElements = fixtureVms
      .map((key, value) => MapEntry(key, FixtureElement(fixtureVm: value)));

  final locationFixtureNodes = graph.nodes
      .whereType<FixtureNode>()
      .where((node) => node.locationId == selectedLocationId);
  final locationCableEdges = graph.edges
      .whereType<CableEdge>()
      .where((edge) => edge.locationId == selectedLocationId);

  return CableViewViewModel(
      nodes: mappedFixtureElements.isNotEmpty
          ? locationFixtureNodes
              .map((node) => mappedFixtureElements[node.id]!)
              .toList()
          : [],
      edges: mappedFixtureElements.isNotEmpty
          ? locationCableEdges
              .map((edge) => switch (edge) {
                    CableEdge e => CableEdgeElement(
                        type: e.type,
                        length: e.length,
                        destinationElement: mappedFixtureElements[e.to]!,
                        sourceElement: mappedFixtureElements[e.from]!)
                  })
              .toList()
          : []);
}

CableGraph _selectCableGraph(Store<AppState> store) {
  return buildCableGraph(
    fixtures: store.state.fixtureState.fixtures,
    fixtureTypes: store.state.fixtureState.fixtureTypes,
  );
}

List<LocationViewModel> _selectLocations(Store<AppState> store) {
  return store.state.fixtureState.locations.values
      .map((location) => LocationViewModel(
          location: location,
          onSelect: () =>
              store.dispatch(SetBreakoutCablingLocationId(location.uid))))
      .toList();
}

Map<String, FixtureViewModel> _selectLocationFixtures(
    Map<String, FixtureViewModel> fixtureVms, String selectedLocationId) {
  return fixtureVms.values
      .where((vm) => vm.fixture.locationId == selectedLocationId)
      .toModelMap();
}

Map<String, FixtureViewModel> _selectFixtureVms(Store<AppState> store) {
  return store.state.fixtureState.fixtures.values
      .map((fixture) => FixtureViewModel(
          fixture: fixture,
          fixtureType: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
      .toModelMap();
}
