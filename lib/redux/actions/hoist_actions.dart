import 'dart:math';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;
import 'package:sidekick/utils/packable_list.dart';

import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> deleteHoistController(
  BuildContext context,
  HoistControllerModel controller,
) {
  return (Store<AppState> store) async {
    final dialogResult = await showGenericDialog(
      context: context,
      title: 'Delete Motor Controller',
      message: 'Are you sure you want to delete ${controller.name}?',
      affirmativeText: 'Delete',
      destructiveAffirmative: true,
      declineText: 'Cancel',
    );

    if (dialogResult == true) {
      final associatedHoists = store.state.fixtureState.hoists.values.where(
        (hoist) => hoist.parentController.controllerId == controller.uid,
      );

      store.dispatch(
        SetHoistsAndControllers(
          hoistControllers: store.state.fixtureState.hoistControllers.clone()
            ..remove(controller.uid),
          hoists: store.state.fixtureState.hoists.clone()
            ..addAll(
              associatedHoists
                  .map(
                    (hoist) => hoist.copyWith(
                      parentController:
                          const HoistControllerChannelAssignment.unassigned(),
                    ),
                  )
                  .toModelMap(),
            ),
        ),
      );

      store.dispatch(SetSelectedHoistChannelIds({}));
    }
  };
}

ThunkAction<AppState> unpatchHoist(
  HoistControllerModel controller,
  HoistModel? hoist,
) {
  return (Store<AppState> store) async {
    if (hoist == null) {
      return;
    }

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()..update(
          hoist.uid,
          (existing) => existing.copyWith(
            parentController:
                const HoistControllerChannelAssignment.unassigned(),
          ),
        ),
      ),
    );
  };
}

ThunkAction<AppState> reorderHoists({
  required int oldIndex,
  required int newIndex,
  required List<HoistModel> hoistsInLocation,
}) {
  return (Store<AppState> store) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final items = hoistsInLocation.toList();

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Assert Number property.
    final assertedItems = items
        .mapIndexed((index, item) => item.copyWith(number: index))
        .toList();

    store.dispatch(SetHoists(assertedItems.toModelMap()));
  };
}

ThunkAction<AppState> deleteSelectedHoistChannels() {
  return (Store<AppState> store) async {
    final hoistIds = store.state.navstate.selectedHoistChannelIds;

    if (hoistIds.isEmpty) {
      return;
    }

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()..updateAll(
          (id, hoist) => hoistIds.contains(id)
              ? hoist.copyWith(
                  parentController:
                      const HoistControllerChannelAssignment.unassigned(),
                )
              : hoist,
        ),
      ),
    );

    store.dispatch(SetSelectedHoistChannelIds({}));
  };
}

ThunkAction<AppState> assignHoistsToController({
  required Set<String> movingOrIncomingHoistIds,
  required int startingChannelNumber,
  required String targetControllerId,
}) {
  return (Store<AppState> store) async {
    if (movingOrIncomingHoistIds.isEmpty ||
        store.state.fixtureState.hoistControllers[targetControllerId] == null) {
      return;
    }

    final controller =
        store.state.fixtureState.hoistControllers[targetControllerId];

    if (controller == null) {
      return;
    }

    // Collect all Hoists currently assigned to this controller.
    final hoistsInController = store.state.fixtureState.hoists.values
        .where((hoist) => hoist.parentController.controllerId == controller.uid)
        .toList();

    // Convert assigned hoists into [IndexedSpots].
    // Do not include any Hoists that are incoming or Moving, these are going to get inserted in the next step anyway.
    final occupiedSlots = hoistsInController
        .where((hoist) => movingOrIncomingHoistIds.contains(hoist.uid) == false)
        .map(
          (hoist) => IndexedSpot<String>(
            hoist.parentController.channel - 1,
            hoist.uid,
          ),
        );

    final packableList = PackableList.fromIndexedSpots(
      occupiedSlots,
      max(
        controller.ways,
        HoistModel.getHighestChannelNumber(hoistsInController) - 1,
      ),
    );

    packableList.insert(movingOrIncomingHoistIds, startingChannelNumber - 1);

    final updatedHoists = packableList
        .toIndexedSpotList()
        .where((slot) => slot.content != null)
        .map(
          (slot) => store.state.fixtureState.hoists[slot.content]!.copyWith(
            parentController: HoistControllerChannelAssignment(
              controllerId: controller.uid,
              channel: slot.index + 1,
            ),
          ),
        );

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()
          ..addAll(updatedHoists.toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> addHoistController(int wayNumber) {
  return (Store<AppState> store) async {
    final String uid = getUid();
    store.dispatch(
      SetHoistControllers(
        store.state.fixtureState.hoistControllers.clone()..addAll({
          uid: HoistControllerModel(
            uid: uid,
            name:
                '${wayNumber}way Motor Controller #${store.state.fixtureState.hoistControllers.values.where((controller) => controller.ways == wayNumber).length + 1}',
            ways: wayNumber,
          ),
        }),
      ),
    );
  };
}

ThunkAction<AppState> selectHoistOutlets(
  UpdateType type,
  Set<String> hoistIds,
) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedHoistOutlets(hoistIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(
          SetSelectedHoistOutlets(
            store.state.navstate.selectedHoistIds.toSet()
              ..addAllIfAbsentElseRemove(hoistIds),
          ),
        );
    }
  };
}

ThunkAction<AppState> selectHoistControllerChannels(
  UpdateType type,
  Set<String> hoistIds,
) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedHoistChannelIds(hoistIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(
          SetSelectedHoistChannelIds(
            store.state.navstate.selectedHoistChannelIds.toSet()
              ..addAllIfAbsentElseRemove(hoistIds),
          ),
        );
    }
  };
}

ThunkAction<AppState> updateHoistName(String hoistId, String newValue) {
  return (Store<AppState> store) async {
    final hoist = store.state.fixtureState.hoists[hoistId];

    if (hoist == null) {
      return;
    }

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()..update(
          hoistId,
          (existing) => existing.copyWith(name: newValue.trim()),
        ),
      ),
    );
  };
}

ThunkAction<AppState> deleteHoist(String hoistId) {
  return (Store<AppState> store) async {
    if (hoistId.isEmpty ||
        store.state.fixtureState.hoists.containsKey(hoistId) == false) {
      return;
    }

    store.dispatch(
      SetHoists(store.state.fixtureState.hoists.clone()..remove(hoistId)),
    );
  };
}

ThunkAction<AppState> addHoist(String locationId) {
  return (Store<AppState> store) async {
    final location = store.state.fixtureState.locations[locationId];

    if (location == null) {
      return;
    }

    final existingHoistsInLocation = store.state.fixtureState.hoists.values
        .where((hoist) => hoist.locationId == locationId)
        .toList();

    final newHoist = HoistModel(
      uid: getUid(),
      name: HoistModel.getDefaultName(
        otherHoistsInLocation: existingHoistsInLocation,
        location: location,
      ),
      locationId: locationId,
      number: existingHoistsInLocation.length,
      parentController: const HoistControllerChannelAssignment.unassigned(),
      controllerNote: '',
    );

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()
          ..addAll({newHoist.uid: newHoist}),
      ),
    );
  };
}
