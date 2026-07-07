import 'dart:math';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/data_rack_type_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';
import 'package:sidekick/screens/locations/power_feed_manager.dart';
import 'package:sidekick/utils/packable_list.dart';

import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> updatePowerRackFeed(String feedId, String targetRackId) {
  return (Store<AppState> store) async {
    final feed = store.state.fixtureState.powerFeeds[feedId];
    final rack = store.state.fixtureState.powerRacks[targetRackId];

    if (feed == null || rack == null) {
      return;
    }

    store.dispatch(
      SetPowerRacks(
        store.state.fixtureState.powerRacks.clone()..update(
          targetRackId,
          (existing) => existing.copyWith(powerFeedId: feedId),
        ),
      ),
    );
  };
}

ThunkAction<AppState> showPowerFeedManager(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await openShadSheet(
      context: context,
      builder: (context) => PowerFeedManager(
        existingPowerFeeds: store.state.fixtureState.powerFeeds.clone(),
      ),
    );

    if (result == null || result is! PowerFeedManagerResult) {
      return;
    }

    // Ensure no Power Racks are assigned to a now deleted Power feed. If they are, assign them to the default feed.
    final updatedPowerRacks = store.state.fixtureState.powerRacks.clone()
      ..updateAll(
        (rackId, rack) => result.deletedFeedIds.contains(rack.powerFeedId)
            ? rack.copyWith(powerFeedId: PowerFeedModel.kDefaultPowerFeedId)
            : rack,
      );

    store.dispatch(
      SetPowerFeedsAndPowerRacks(
        powerFeeds: result.powerFeeds,
        racks: updatedPowerRacks,
      ),
    );
  };
}

ThunkAction<AppState> assignPowerRackToFeed(String feedId, String rackId) {
  return (Store<AppState> store) async {
    final rack = store.state.fixtureState.powerRacks[rackId];

    if (rack == null) {
      return;
    }

    store.dispatch(
      SetPowerRacks(
        store.state.fixtureState.powerRacks.clone()
          ..update(rack.uid, (_) => rack.copyWith(powerFeedId: feedId)),
      ),
    );
  };
}

ThunkAction<AppState> assignPowerMultisToRack({
  required Set<String> movingOrIncomingMultiIds,
  required int startingChannelNumber,
  required String targetRackId,
}) {
  return (Store<AppState> store) async {
    if (movingOrIncomingMultiIds.isEmpty ||
        store.state.fixtureState.powerRacks[targetRackId] == null) {
      return;
    }

    final rack = store.state.fixtureState.powerRacks[targetRackId];

    if (rack == null) {
      return;
    }

    final rackType = store.state.fixtureState.powerRackTypes[rack.typeId];

    if (rackType == null) {
      return;
    }

    // Collect all Multis currently assigned to this Rack.
    final multisInRack = store.state.fixtureState.powerMultiOutlets.values
        .where((multi) => multi.parentRack.rackId == rack.uid)
        .toList();

    // Convert assigned Multis into [IndexedSpots].
    // Do not include any Multis that are incoming or Moving, these are going to get inserted in the next step anyway.
    final occupiedSlots = multisInRack
        .where((multi) => movingOrIncomingMultiIds.contains(multi.uid) == false)
        .map(
          (multi) =>
              IndexedSpot<String>(multi.parentRack.channel - 1, multi.uid),
        );

    final packableList = PackableList.fromIndexedSpots(
      occupiedSlots,
      max(
        rackType.multiOutletCount,
        PowerMultiOutletModel.getHighestChannelNumber(multisInRack) - 1,
      ),
    );

    packableList.insert(movingOrIncomingMultiIds, startingChannelNumber - 1);

    final updatedPowerMultis = packableList
        .toIndexedSpotList()
        .where((slot) => slot.content != null)
        .map(
          (slot) => store.state.fixtureState.powerMultiOutlets[slot.content]!
              .copyWith(
                parentRack: PowerMultiRackAssignment(
                  rackId: rack.uid,
                  channel: slot.index + 1,
                ),
              ),
        );

    store.dispatch(
      SetPowerMultiOutlets(
        store.state.fixtureState.powerMultiOutlets.clone()
          ..addAll(updatedPowerMultis.toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> assignDataPatchesToRack({
  required Set<String> movingOrIncomingPatchIds,
  required int startingChannelNumber,
  required String targetRackId,
}) {
  return (Store<AppState> store) async {
    if (movingOrIncomingPatchIds.isEmpty ||
        store.state.fixtureState.dataRacks[targetRackId] == null) {
      return;
    }

    final rack = store.state.fixtureState.dataRacks[targetRackId];

    if (rack == null) {
      return;
    }

    final rackType = store.state.fixtureState.dataRackTypes[rack.typeId];

    if (rackType == null) {
      return;
    }

    // Collect all Patches currently assigned to this Rack.
    final patchesInRack = store.state.fixtureState.dataPatches.values
        .where((multi) => multi.parentRack.rackId == rack.uid)
        .toList();

    // Convert assigned Patches into [IndexedSpots].
    // Do not include any Patches that are incoming or Moving, these are going to get inserted in the next step anyway.
    final occupiedSlots = patchesInRack
        .where((patch) => movingOrIncomingPatchIds.contains(patch.uid) == false)
        .map(
          (patch) =>
              IndexedSpot<String>(patch.parentRack.channel - 1, patch.uid),
        );

    final packableList = PackableList.fromIndexedSpots(
      occupiedSlots,
      max(
        rackType.outletCount,
        DataPatchModel.getHighestChannelNumber(patchesInRack) - 1,
      ),
    );

    packableList.insert(movingOrIncomingPatchIds, startingChannelNumber - 1);

    final updatedDataPatches = packableList
        .toIndexedSpotList()
        .where((slot) => slot.content != null)
        .map(
          (slot) =>
              store.state.fixtureState.dataPatches[slot.content]!.copyWith(
                parentRack: DataPatchRackAssignment(
                  rackId: rack.uid,
                  channel: slot.index + 1,
                ),
              ),
        );

    store.dispatch(
      SetDataPatches(
        store.state.fixtureState.dataPatches.clone()
          ..addAll(updatedDataPatches.toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> addPowerRack(BuildContext context) {
  return (Store<AppState> store) async {
    final PowerRackTypeModel? rackType = await openShadSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Add Power Rack').large,
            ),
            ...store.state.fixtureState.powerRackTypes.values.map(
              (type) => TextButton(
                child: Text(type.name),
                onPressed: () => Navigator.of(context).pop(type),
              ),
            ),
          ],
        ),
      ),
    );

    if (rackType == null) {
      return;
    }

    final existingRacksOfType = store.state.fixtureState.powerRacks.values
        .where((rack) => rack.typeId == rackType.uid);

    final newRack = PowerRackModel(
      uid: getUid(),
      name: '${rackType.name} #${existingRacksOfType.length + 1}',
      typeId: rackType.uid,
      powerFeedId: const PowerFeedModel.defaultFeed().uid,
      note: '',
    );

    store.dispatch(
      SetPowerRacks(
        store.state.fixtureState.powerRacks.clone()
          ..addAll({newRack.uid: newRack}),
      ),
    );
  };
}

ThunkAction<AppState> addDataRack(BuildContext context) {
  return (Store<AppState> store) async {
    final DataRackTypeModel? rackType = await openShadSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Add Data Rack').large,
            ),
            ...store.state.fixtureState.dataRackTypes.values.map(
              (type) => TextButton(
                child: Text(type.name),
                onPressed: () => Navigator.of(context).pop(type),
              ),
            ),
          ],
        ),
      ),
    );

    if (rackType == null) {
      return;
    }

    final existingRacksOfType = store.state.fixtureState.dataRacks.values.where(
      (rack) => rack.typeId == rackType.uid,
    );

    final newRack = DataRackModel(
      uid: getUid(),
      name: '${rackType.name} #${existingRacksOfType.length + 1}',
      typeId: rackType.uid,
      notes: '',
    );

    store.dispatch(
      SetDataRacks(
        store.state.fixtureState.dataRacks.clone()
          ..addAll({newRack.uid: newRack}),
      ),
    );
  };
}

ThunkAction<AppState> updatePowerRackType(String rackId, String typeId) {
  return (Store<AppState> store) async {
    final rack = store.state.fixtureState.powerRacks[rackId];
    final type = store.state.fixtureState.powerRackTypes[typeId];

    if (rack == null || type == null) {
      return;
    }

    store.dispatch(
      SetPowerRacks(
        store.state.fixtureState.powerRacks.clone()
          ..update(rackId, (existing) => existing.copyWith(typeId: typeId)),
      ),
    );
  };
}

ThunkAction<AppState> updateDataRackType(String rackId, String typeId) {
  return (Store<AppState> store) async {
    final rack = store.state.fixtureState.dataRacks[rackId];
    final type = store.state.fixtureState.dataRackTypes[typeId];

    if (rack == null || type == null) {
      return;
    }

    store.dispatch(
      SetDataRacks(
        store.state.fixtureState.dataRacks.clone()
          ..update(rackId, (existing) => existing.copyWith(typeId: typeId)),
      ),
    );
  };
}

ThunkAction<AppState> deleteDataRack(BuildContext context, DataRackModel rack) {
  return (Store<AppState> store) async {
    final dialogResult = await showGenericDialog(
      context: context,
      title: 'Delete Data rack',
      message: 'Are you sure you want to delete ${rack.name}?',
      affirmativeText: 'Delete',
      destructiveAffirmative: true,
      declineText: 'Cancel',
    );

    if (dialogResult == true) {
      final updatedDataPatches = store.state.fixtureState.dataPatches.clone()
        ..updateAll(
          (patchId, existing) => existing.parentRack.rackId == rack.uid
              ? existing.copyWith(
                  parentRack: const DataPatchRackAssignment.unassigned(),
                )
              : existing,
        );

      store.dispatch(SetDataPatches(updatedDataPatches));

      store.dispatch(
        SetPowerRacks(
          store.state.fixtureState.powerRacks.clone()..remove(rack.uid),
        ),
      );
    }
  };
}

ThunkAction<AppState> deletePowerRack(
  BuildContext context,
  PowerRackModel rack,
) {
  return (Store<AppState> store) async {
    final dialogResult = await showGenericDialog(
      context: context,
      title: 'Delete power rack',
      message: 'Are you sure you want to delete ${rack.name}?',
      affirmativeText: 'Delete',
      destructiveAffirmative: true,
      declineText: 'Cancel',
    );

    if (dialogResult == true) {
      final updatedPowerMultis =
          store.state.fixtureState.powerMultiOutlets.clone()..updateAll(
            (multiId, existing) => existing.parentRack.rackId == rack.uid
                ? existing.copyWith(
                    parentRack: const PowerMultiRackAssignment.unassigned(),
                  )
                : existing,
          );

      store.dispatch(SetPowerMultiOutlets(updatedPowerMultis));

      store.dispatch(
        SetPowerRacks(
          store.state.fixtureState.powerRacks.clone()..remove(rack.uid),
        ),
      );
    }
  };
}
