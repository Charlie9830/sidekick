import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/assert_cable_state.dart';

/// Handles hoist-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceHoistActions(FixtureState state, dynamic a) {
  if (a is SetHoistsAndControllers) {
    return state.copyWith(
      hoists: a.hoists,
      hoistControllers: a.hoistControllers,
    );
  }

  if (a is UpdateHoistNote) {
    return state.copyWith(
      hoists: state.hoists.clone()
        ..update(
          a.id,
          (existing) => existing.copyWith(controllerNote: a.value.trim()),
        ),
    );
  }

  if (a is SetHoists) {
    return state.copyWith(
      hoists: a.value,
      cables: assertCableState(
        cables: state.cables,
        powerMultiOutlets: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches,
        hoistOutlets: a.value,
        hoistMultis: state.hoistMultis,
      ),
    );
  }

  if (a is SetHoistControllers) {
    return state.copyWith(hoistControllers: a.value);
  }

  if (a is UpdateHoistControllerName) {
    return state.copyWith(
      hoistControllers: state.hoistControllers.clone()
        ..update(
          a.hoistId,
          (existing) => existing.copyWith(name: a.value.trim()),
        ),
    );
  }

  if (a is UpdateHoistControllerWayCount) {
    return state.copyWith(
      hoistControllers: state.hoistControllers.clone()
        ..update(a.hoistId, (existing) => existing.copyWith(ways: a.value)),
    );
  }

  if (a is SetHoistMultis) {
    return state.copyWith(
      hoistMultis: assertMultiOutletState<HoistMultiModel>(
        multiOutlets: a.multis,
        locations: state.locations,
        cables: state.cables,
      ),
    );
  }

  return null;
}
