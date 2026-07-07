// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/breakout_cabling/breakout_cabling.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

/// The viewpoint used to flatten the 3D rig into the cable view. Swapping this
/// (e.g. for a front or side view) re-orients fixtures, cables and trusses
/// together, because every world coordinate is projected through it here at the
/// container level rather than in the widgets.
const ViewProjection _kProjection = PlanProjection();

/// Diagram-space nudge (mm) that lifts header/location markers clear of the
/// fixtures they serve, so overlapping outlets stay legible. Presentation only;
/// it never feeds into cable-length calculations.
const double _kHeaderDiagramOffsetMm = 600;

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
            locationVms: _selectLocations(store, cableGraph),
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
      trusses: _selectTrussVms(store, _kProjection),
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
        node.id,
        () => _buildNodeElement(
            node: node, fixtureVms: fixtureVms, projection: _kProjection));

    for (final edge in node.edges) {
      edgeElements.add(_buildEdgeElement(
          edge: edge,
          fromElement: nodeElements.putIfAbsent(
              edge.from,
              () => _buildNodeElement(
                  node: graph.getNode(edge.from)!,
                  fixtureVms: fixtureVms,
                  projection: _kProjection)),
          toElement: nodeElements.putIfAbsent(
              edge.to,
              () => _buildNodeElement(
                  node: graph.getNode(edge.to)!,
                  fixtureVms: fixtureVms,
                  projection: _kProjection))));
    }
  }

  return CableViewViewModel(
    elements: nodeElements.values.toList(),
    edges: edgeElements,
    trusses: _selectTrussVms(store, _kProjection),
    cableVisibility: store.state.navstate.breakoutCableVisibility,
    onVisibilityChanged: (value) => store.dispatch(
      SetBreakoutCableVisibilityState(value),
    ),
  );
}

NodeElement _buildNodeElement({
  required Node node,
  required Map<String, FixtureViewModel> fixtureVms,
  required ViewProjection projection,
}) {
  switch (node) {
    case FixtureNode():
      final fixtureVm = fixtureVms[node.id]!;
      final fixture = fixtureVm.fixture;
      final p = projection.project(fixture.x, fixture.y, fixture.z);
      return FixtureElement(
          fixtureVm: fixtureVm, screenX: p.dx, screenY: p.dy);
    case PowerMultiHeaderNode():
      final p = _projectHeader(projection, node.x, node.y, node.z);
      return PowerMultiHeaderElement(
          screenX: p.dx,
          screenY: p.dy,
          powerMultiVm: PowerMultiHeaderViewModel(
              type: node.cableType, name: node.outletName));
    case LocationNode():
      final p = _projectHeader(projection, node.x, node.y, node.z);
      return LocationElement(
          locationId: node.locationId, screenX: p.dx, screenY: p.dy);
    case DataMultiHeaderNode():
      final p = _projectHeader(projection, node.x, node.y, node.z);
      return DataMultiHeaderElement(
          outletName: node.outletName, screenX: p.dx, screenY: p.dy);
    case DataPatchHeaderNode():
      final p = _projectHeader(projection, node.x, node.y, node.z);
      return DataPatchHeaderElement(
          outletName: node.outletName,
          universe: node.universe,
          screenX: p.dx,
          screenY: p.dy);
    case TrussBreakNode():
      final p = projection.project(node.x, node.y, node.z);
      return TrussBreakElement(screenX: p.dx, screenY: p.dy);
  }
}

/// Projects a header/location marker and lifts it clear of its fixtures.
Offset _projectHeader(
        ViewProjection projection, double x, double y, double z) =>
    projection
        .project(x, y, z)
        .translate(0, -_kHeaderDiagramOffsetMm);

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

List<TrussViewModel> _selectTrussVms(
    Store<AppState> store, ViewProjection projection) {
  return store.state.fixtureState.trusses.values
      .where((truss) => truss.length > 0)
      .map((truss) => TrussViewModel(
            uid: truss.uid,
            name: truss.name,
            hull: _projectTrussHull(truss, projection),
          ))
      .toList();
}

/// Projects a truss's eight world corners into diagram space and returns their
/// outline, so the painter draws the correct footprint for any orientation.
List<Offset> _projectTrussHull(TrussModel truss, ViewProjection projection) {
  final halfLength = truss.lengthAxis * (truss.length / 2);
  final halfWidth = truss.widthAxis * (truss.width / 2);
  final halfHeight = truss.heightAxis * (truss.height / 2);

  final corners = <Offset>[
    for (final sl in const [-1.0, 1.0])
      for (final sw in const [-1.0, 1.0])
        for (final sh in const [-1.0, 1.0])
          projection.projectVector(truss.center +
              halfLength * sl +
              halfWidth * sw +
              halfHeight * sh),
  ];

  return convexHull(corners);
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
    trusses: store.state.fixtureState.trusses,
  );
}

List<LocationViewModel> _selectLocations(
    Store<AppState> store, CableGraph cableGraph) {
  final cablesByLocationId = selectCableQtysByLocationId(cableGraph);

  return store.state.fixtureState.locations.values
      .map((location) => LocationViewModel(
          cableQtys: cablesByLocationId[location.uid] ?? {},
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
