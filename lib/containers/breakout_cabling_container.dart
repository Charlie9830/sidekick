// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
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
              store: store,
            ));
      },
    );
  }
}

CableViewViewModel _selectCableViewVm({
  required CableGraph graph,
  required Map<String, FixtureViewModel> fixtureVms,
  required String selectedLocationId,
  required Store<AppState> store,
}) {
  final locationNode = graph.getNode(selectedLocationId);

  if (locationNode == null) {
    return CableViewViewModel(
      elements: [],
      edges: [],
      cableVisibility: store.state.navstate.breakoutCableVisibility,
      onVisibilityChanged: (value) => store.dispatch(
        SetBreakoutCableVisibilityState(value),
      ),
    );
  }

  final nodeElements = <String, NodeElement>{};
  final edgeElements = <EdgeElement>[];

  for (final node in graph.walk(locationNode)) {
    nodeElements.putIfAbsent(
        node.id, () => _buildNodeElement(node: node, fixtureVms: fixtureVms));

    for (final edge in node.edges) {
      edgeElements.add(_buildEdgeElement(
          edge: edge,
          fromElement: nodeElements.putIfAbsent(
              edge.from,
              () => _buildNodeElement(
                  node: graph.getNode(edge.from)!, fixtureVms: fixtureVms)),
          toElement: nodeElements.putIfAbsent(
              edge.to,
              () => _buildNodeElement(
                  node: graph.getNode(edge.to)!, fixtureVms: fixtureVms))));
    }
  }

  return CableViewViewModel(
    elements: nodeElements.values.toList(),
    edges: edgeElements,
    cableVisibility: store.state.navstate.breakoutCableVisibility,
    onVisibilityChanged: (value) => store.dispatch(
      SetBreakoutCableVisibilityState(value),
    ),
  );
}

NodeElement _buildNodeElement({
  required Node node,
  required Map<String, FixtureViewModel> fixtureVms,
}) {
  return switch (node) {
    FixtureNode() => FixtureElement(fixtureVm: fixtureVms[node.id]!),
    PowerMultiHeaderNode() => PowerMultiHeaderElement(
        screenX: node.screenX,
        screenY: node.screenY,
        powerMultiVm: PowerMultiHeaderViewModel(
            type: node.cableType, name: node.outletName)),
    LocationNode() => LocationElement(
        locationId: node.locationId,
        screenX: node.screenX,
        screenY: node.screenY),
    DataMultiHeaderNode() => DataMultiHeaderElement(
        outletName: node.outletName,
        screenX: node.screenX,
        screenY: node.screenY),
    DataPatchHeaderNode() => DataPatchHeaderElement(
        outletName: node.outletName,
        universe: node.universe,
        screenX: node.screenX,
        screenY: node.screenY),
  };
}

EdgeElement _buildEdgeElement(
    {required Edge edge,
    required NodeElement fromElement,
    required NodeElement toElement}) {
  return switch (edge) {
    PsuedoEdge() => PsuedoEdgeElement(
        fromElement: fromElement,
        toElement: toElement,
      ),
    CableEdge() => CableEdgeElement(
        type: edge.type,
        length: edge.length,
        runType: edge.runType,
        toElement: toElement,
        fromElement: fromElement)
  };
}

CableGraph _selectCableGraph(Store<AppState> store) {
  return buildCableGraph(
    fixtures: store.state.fixtureState.fixtures,
    fixtureTypes: store.state.fixtureState.fixtureTypes,
    powerMultis: store.state.fixtureState.powerMultiOutlets,
    cables: store.state.fixtureState.cables,
    locations: store.state.fixtureState.locations,
    dataMultis: store.state.fixtureState.dataMultis,
    dataPatches: store.state.fixtureState.dataPatches,
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
