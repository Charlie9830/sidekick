import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

List<PowerPatchRowViewModel> selectPowerPatchViewModels(Store<AppState> store) {
  return store.state.fixtureState.locations.values
      .map((location) {
        final associatedMultis = store
            .state.fixtureState.powerMultiOutlets.values
            .where((multi) => multi.locationId == location.uid)
            .toList();

        return [
          LocationRowViewModel(
              location: location,
              multiCount: associatedMultis.length,
              onLockChanged: (value) =>
                  store.dispatch(SetLocationPowerLock(location.uid, value))),
          ...associatedMultis.map((multi) => MultiOutletRowViewModel(
              multi,
              multi.children
                  .map(
                    (outlet) => PowerOutletVM(
                        outlet: outlet,
                        fixtureVms: outlet.fixtureIds.map((id) {
                          final fixture =
                              store.state.fixtureState.fixtures[id]!;

                          return FixtureOutletVM(
                              fixture: fixture,
                              type: store.state.fixtureState
                                  .fixtureTypes[fixture.typeId]!);
                        }).toList()),
                  )
                  .toList())),
        ];
      })
      .flattened
      .toList();
}
