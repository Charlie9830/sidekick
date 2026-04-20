import 'package:redux/redux.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/state/app_state.dart';

LocationModel? selectCableLocation(CableModel cable, Store<AppState> store) {
  final locationId = switch (cable.type) {
    CableType.dmx =>
      store.state.fixtureState.dataPatches[cable.outletId]?.locationId,
    CableType.socapex ||
    CableType.wieland6way =>
      store.state.fixtureState.powerMultiOutlets[cable.outletId]?.locationId,
    CableType.sneak =>
      store.state.fixtureState.dataMultis[cable.outletId]?.locationId,
    CableType.hoist =>
      store.state.fixtureState.hoists[cable.outletId]?.locationId,
    CableType.hoistMulti =>
      store.state.fixtureState.hoistMultis[cable.outletId]?.locationId,
    CableType.au10a => '',
    CableType.unknown => throw UnimplementedError(),
    CableType.true1 => throw UnimplementedError(),
    CableType.socapexToAu10ALampHeader => throw UnimplementedError(),
    CableType.socapexToTrue1LampHeader => throw UnimplementedError(),
    CableType.wieland6WayLampHeader => throw UnimplementedError(),
    CableType.sneakLampHeader => throw UnimplementedError(),
    CableType.hoistMultiLampHeader => throw UnimplementedError(),
    CableType.hoistMultiRackHeader => throw UnimplementedError(),
  };

  return store.state.fixtureState.locations[locationId];
}
