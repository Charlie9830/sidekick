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
      store.state.fixtureState.dataMultis[cable.outletId]?.locationIds.first,
    CableType.unknown => throw UnimplementedError(),
  };

  return store.state.fixtureState.locations[locationId];
}
