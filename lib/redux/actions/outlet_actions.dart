import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';

import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/state/app_state.dart';

ThunkAction<AppState> selectPowerMultiOutlets(
  UpdateType type,
  Set<String> multiIds,
) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedPowerMultiOutletIds(multiIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(
          SetSelectedPowerMultiOutletIds(
            store.state.navstate.selectedPowerMultiOutletIds.toSet()
              ..addAllIfAbsentElseRemove(multiIds),
          ),
        );
    }
  };
}

ThunkAction<AppState> selectPowerMultiChannels(
  UpdateType type,
  Set<String> multiIds,
) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedPowerMultiChannelIds(multiIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(
          SetSelectedPowerMultiChannelIds(
            store.state.navstate.selectedPowerMultiChannelIds.toSet()
              ..addAllIfAbsentElseRemove(multiIds),
          ),
        );
    }
  };
}

ThunkAction<AppState> unpatchPowerMulti(
  PowerRackModel powerRack,
  String? multiId,
) {
  return (Store<AppState> store) async {
    if (multiId == null) {
      return;
    }

    final multi = store.state.fixtureState.powerMultiOutlets[multiId];

    if (multi == null) {
      return;
    }

    store.dispatch(
      SetPowerMultiOutlets(
        store.state.fixtureState.powerMultiOutlets.clone()..update(
          multi.uid,
          (existing) => existing.copyWith(
            parentRack: const PowerMultiRackAssignment.unassigned(),
          ),
        ),
      ),
    );
  };
}

ThunkAction<AppState> unpatchPowerMultis(Set<String> powerMultiIds) {
  return (Store<AppState> store) async {
    if (powerMultiIds.isEmpty) {
      return;
    }

    store.dispatch(
      SetPowerMultiOutlets(
        store.state.fixtureState.powerMultiOutlets.clone()..updateAll(
          (multiId, existing) => powerMultiIds.contains(multiId)
              ? existing.copyWith(
                  parentRack: const PowerMultiRackAssignment.unassigned(),
                )
              : existing,
        ),
      ),
    );
  };
}

ThunkAction<AppState> unpatchDataOutlet(
  DataRackModel dataRack,
  String? patchId,
) {
  return (Store<AppState> store) async {
    if (patchId == null) {
      return;
    }

    final patch = store.state.fixtureState.dataPatches[patchId];

    if (patch == null) {
      return;
    }

    store.dispatch(
      SetDataPatches(
        store.state.fixtureState.dataPatches.clone()..update(
          patch.uid,
          (existing) => existing.copyWith(
            parentRack: const DataPatchRackAssignment.unassigned(),
          ),
        ),
      ),
    );
  };
}

ThunkAction<AppState> unpatchDataOutlets(Set<String> patchIds) {
  return (Store<AppState> store) async {
    if (patchIds.isEmpty) {
      return;
    }

    store.dispatch(
      SetDataPatches(
        store.state.fixtureState.dataPatches.clone()..updateAll(
          (patchId, existing) => patchIds.contains(patchId)
              ? existing.copyWith(
                  parentRack: const DataPatchRackAssignment.unassigned(),
                )
              : existing,
        ),
      ),
    );
  };
}

ThunkAction<AppState> addSpareOutlet(String uid) {
  return (Store<AppState> store) async {
    final multiOutlet = store.state.fixtureState.powerMultiOutlets[uid];

    if (multiOutlet == null) {
      return;
    }

    if (multiOutlet.desiredSpareCircuits >= 6) {
      return;
    }

    _updatePowerMultiSpareCircuitCount(
      store,
      uid,
      multiOutlet.desiredSpareCircuits + 1,
    );
  };
}

ThunkAction<AppState> deleteSpareOutlet(String uid) {
  return (Store<AppState> store) async {
    final multiOutlet = store.state.fixtureState.powerMultiOutlets[uid];

    if (multiOutlet == null) {
      return;
    }

    if (multiOutlet.desiredSpareCircuits <= 0) {
      return;
    }

    _updatePowerMultiSpareCircuitCount(
      store,
      uid,
      multiOutlet.desiredSpareCircuits - 1,
    );
  };
}

void _updatePowerMultiSpareCircuitCount(
  Store<AppState> store,
  String uid,
  int desiredCount,
) {
  final existingMultiOutlets = store.state.fixtureState.powerMultiOutlets;

  existingMultiOutlets.update(
    uid,
    (existing) => existing.copyWith(desiredSpareCircuits: desiredCount),
  );

  store.dispatch(SetPowerMultiOutlets(existingMultiOutlets));
}
