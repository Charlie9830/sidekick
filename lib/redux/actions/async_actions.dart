// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/excel/create_fixture_info_sheet.dart';
import 'package:sidekick/excel/create_hoist_patch_sheet.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/screens/hoists/add_or_edit_rigging_location.dart';
import 'package:sidekick/toasts.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sidekick/assert_sneak_child_spares.dart';
import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/classes/export_file_paths.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/containers/import_manager_container.dart';
import 'package:sidekick/data_selectors/select_all_outlets.dart';
import 'package:sidekick/data_selectors/select_outlets.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_addressing_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_lighting_looms_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/extension_methods/greater_of.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/helpers/apply_cable_action_modifiers.dart';
import 'package:sidekick/helpers/cable_combiners.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/helpers/determine_default_loom_name.dart';
import 'package:sidekick/helpers/extract_locations_from_outlets.dart';
import 'package:sidekick/helpers/fill_cables_to_satisfy_permanent_loom.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/model_collection/convert_to_map_entry.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/init_persistent_settings_storage.dart';
import 'package:sidekick/persistent_settings/update_persistent_settings.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/import_module/import_manager_result.dart';
import 'package:sidekick/screens/location_overrides_dialog/location_overrides_dialog.dart';
import 'package:sidekick/screens/looms/add_spare_cables.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/screens/setup_quantities_dialog/setup_quantities_dialog.dart';
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> deleteHoistController(
    BuildContext context, HoistControllerModel controller) {
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
          (hoist) => hoist.parentController.controllerId == controller.uid);

      store.dispatch(SetHoistsAndControllers(
          hoistControllers: store.state.fixtureState.hoistControllers.clone()
            ..remove(controller.uid),
          hoists: store.state.fixtureState.hoists.clone()
            ..addAll(
              associatedHoists
                  .map((hoist) => hoist.copyWith(
                      parentController:
                          const HoistControllerChannelAssignment.unassigned()))
                  .toModelMap(),
            )));

      store.dispatch(SetSelectedHoistChannelIds({}));
    }
  };
}

ThunkAction<AppState> unpatchHoist(
    HoistControllerModel controller, HoistModel? hoist) {
  return (Store<AppState> store) async {
    if (hoist == null) {
      return;
    }

    store.dispatch(SetHoists(store.state.fixtureState.hoists.clone()
      ..update(
          (hoist.uid),
          (existing) => existing.copyWith(
                parentController:
                    const HoistControllerChannelAssignment.unassigned(),
              ))));
  };
}

ThunkAction<AppState> reorderHoists(int oldIndex, int newIndex,
    List<HoistItemBase> hoistItems, BuildContext context) {
  return (Store<AppState> store) async {
    if (_validateAndNotifyHoistMove(oldIndex, newIndex, hoistItems, context) ==
        false) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final itemVms = hoistItems.toList();

    final item = itemVms.removeAt(oldIndex);
    itemVms.insert(newIndex, item);

    final hoists = itemVms.whereType<HoistViewModel>().map((vm) => vm.hoist);

    store.dispatch(SetHoists(hoists.toModelMap()));
  };
}

class LocationSpan {
  final LocationModel location;
  final int startingIndex;
  int? endingIndex;

  LocationSpan({
    required this.location,
    required this.startingIndex,
  });

  bool get isClosed => endingIndex != null;

  bool containsIndex(int index) =>
      index >= startingIndex && endingIndex != null && index <= endingIndex!;
}

ThunkAction<AppState> deleteLocation(BuildContext context, String locationId) {
  return (Store<AppState> store) async {
    final location = store.state.fixtureState.locations[locationId];

    if (location == null || location.isRiggingOnlyLocation == false) {
      return;
    }

    final result = await showGenericDialog(
        context: context,
        title: 'Delete Location',
        message:
            'Are you sure you want to delete ${location.name}. All motors and cables associated with this location will be deleted as well.',
        affirmativeText: 'Delete',
        destructiveAffirmative: true,
        declineText: 'Cancel');

    if (result == true) {
      store.dispatch(RemoveLocation(
        location: location,
      ));
    }
  };
}

ThunkAction<AppState> editRiggingLocation(
    BuildContext context, LocationModel location) {
  return (Store<AppState> store) async {
    if (location.isRiggingOnlyLocation == false) {
      return;
    }

    final result = await openShadSheet(
        context: context,
        builder: (context) => AddOrEditRiggingLocation(
              existingLocation: location,
            ));

    if (result is AddRiggingLocationDialogResult) {
      final updatedLocation = location.copyWith(
        color: result.labelColor,
        name: result.name,
        multiPrefix: result.prefix,
        delimiter: result.delimiter,
      );

      final updatedPrimaryLocations = store.state.fixtureState.locations.clone()
        ..update(location.uid, (_) => updatedLocation);

      final associatedHybridLocations =
          store.state.fixtureState.locations.values.where(
              (item) => item.isHybrid && item.hybridIds.contains(location.uid));

      final updatedHybridLocations = associatedHybridLocations.map(
          (hybridLoc) => hybridLoc.copyWith(
              name: LocationModel.getHybridLocationName(hybridLoc.hybridIds
                  .map((id) => updatedPrimaryLocations[id])
                  .nonNulls
                  .toList())));

      store.dispatch(SetLocations(updatedPrimaryLocations
        ..addAll(updatedHybridLocations.toModelMap())));
    }
  };
}

ThunkAction<AppState> addRiggingLocation(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await openShadSheet(
        context: context,
        builder: (context) => const AddOrEditRiggingLocation());

    if (result is AddRiggingLocationDialogResult) {
      final newLocation = LocationModel(
        uid: getUid(),
        color: result.labelColor,
        name: result.name,
        multiPrefix: result.prefix,
        delimiter: result.delimiter,
        isRiggingOnlyLocation: true,
      );

      store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
        ..addAll({newLocation.uid: newLocation})));
    }
  };
}

ThunkAction<AppState> deleteSelectedHoistChannels() {
  return (Store<AppState> store) async {
    final hoistIds = store.state.navstate.selectedHoistChannelIds;

    if (hoistIds.isEmpty) {
      return;
    }

    store.dispatch(SetHoists(store.state.fixtureState.hoists.clone()
      ..updateAll((id, hoist) => hoistIds.contains(id)
          ? hoist.copyWith(
              parentController:
                  const HoistControllerChannelAssignment.unassigned())
          : hoist)));

    store.dispatch(SetSelectedHoistChannelIds({}));
  };
}

ThunkAction<AppState> assignHoistsToController(
    {required Set<String> movingOrIncomingHoistIds,
    required int startingChannelNumber,
    required String targetControllerId}) {
  return (Store<AppState> store) async {
    if (movingOrIncomingHoistIds.isEmpty ||
        store.state.fixtureState.hoistControllers[targetControllerId] == null) {
      return;
    }

    final movingOrIncomingHoists = movingOrIncomingHoistIds
        .map((id) => store.state.fixtureState.hoists[id])
        .nonNulls
        .toList();

    if (movingOrIncomingHoists.isEmpty) {
      return;
    }

    final controller =
        store.state.fixtureState.hoistControllers[targetControllerId];

    if (controller == null) {
      return;
    }

    final childHoistsByChannel = store.state.fixtureState.hoists.values
        .where((hoist) =>
            hoist.parentController.controllerId == targetControllerId)
        .groupFoldBy(
            (hoist) => hoist.parentController.channel, (_, hoist) => hoist);

    final movingOrIncomingHoistsWithUpdatedChannels =
        movingOrIncomingHoists.mapIndexed((index, hoist) => hoist.copyWith(
            parentController: hoist.parentController
                .copyWith(channel: startingChannelNumber + index)));

    // Create a list that represents all channels currently in this controller, in their current channels, this includes unpopulated empty channels.
    final allChannels = List.generate(
        HoistModel.getHighestChannelNumber([
          ...childHoistsByChannel.values.toList(),
          ...movingOrIncomingHoistsWithUpdatedChannels
        ]).greaterOf(controller.ways), (index) {
      final originalHoist = childHoistsByChannel[index + 1];
      return _HoistControllerChannel(
        originalHoist: originalHoist,
      );
    });

    final allChannelsWithPrunedMovingHoists = allChannels.map((channel) =>
        movingOrIncomingHoistIds.contains(channel.originalHoist?.uid)
            ? _HoistControllerChannel(originalHoist: null)
            : channel);

    final incomingHoistsQueue = Queue<HoistModel>.from(movingOrIncomingHoists);

    final startingInsertionIndex = startingChannelNumber - 1;
    final channelAccum = allChannelsWithPrunedMovingHoists.foldIndexed(
        _ChannelAccumulator(
            channels: [],
            carry: Queue<_HoistControllerChannel>()), (index, accum, channel) {
      if (incomingHoistsQueue.isEmpty) {
        if (accum.carry.isNotEmpty) {
          return accum.copyWith(
            channels: [
              ...accum.channels,
              accum.carry.removeFirst(),
            ],
            carry: accum.carry..add(channel),
          );
        }

        if (accum.carry.isEmpty) {
          return accum.copyWith(channels: [
            ...accum.channels,
            channel,
          ]);
        }
      }

      if (index < startingInsertionIndex) {
        return accum.copyWith(channels: [
          ...accum.channels,
          channel,
        ]);
      } else {
        if (channel.originalHoist == null) {
          return accum.copyWith(channels: [
            ...accum.channels,
            _HoistControllerChannel(
                originalHoist: incomingHoistsQueue.removeFirst())
          ]);
        } else {
          return accum.copyWith(
            channels: [
              ...accum.channels,
              _HoistControllerChannel(
                  originalHoist: incomingHoistsQueue.removeFirst())
            ],
            carry: accum.carry..add(channel),
          );
        }
      }
    });

    final updatedChannels = [
      ...channelAccum.channels,
      ...channelAccum.carry,
    ];

    final updatedHoists = updatedChannels
        .mapIndexed((index, channel) => channel.originalHoist?.copyWith(
                parentController:
                    channel.originalHoist?.parentController.copyWith(
              channel: index + 1,
              controllerId: targetControllerId,
            )))
        .nonNulls
        .toList();

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()
          ..addAll(
            updatedHoists.toModelMap(),
          ),
      ),
    );

    store.dispatch(SetSelectedHoistChannelIds(movingOrIncomingHoistIds));
  };
}

class _ChannelAccumulator {
  final List<_HoistControllerChannel> channels;
  final Queue<_HoistControllerChannel> carry;

  _ChannelAccumulator({
    required this.channels,
    required this.carry,
  });

  _ChannelAccumulator copyWith({
    List<_HoistControllerChannel>? channels,
    Queue<_HoistControllerChannel>? carry,
  }) {
    return _ChannelAccumulator(
      channels: channels ?? this.channels,
      carry: carry ?? this.carry,
    );
  }
}

class _HoistControllerChannel {
  final HoistModel? originalHoist;

  _HoistControllerChannel({
    required this.originalHoist,
  });

  @override
  String toString() {
    return '$originalHoist';
  }

  _HoistControllerChannel copyWith({
    HoistModel? originalHoist,
    bool? dirty,
  }) {
    return _HoistControllerChannel(
      originalHoist: originalHoist ?? this.originalHoist,
    );
  }
}

ThunkAction<AppState> addHoistController(int wayNumber) {
  return (Store<AppState> store) async {
    final String uid = getUid();
    store.dispatch(SetHoistControllers(
      store.state.fixtureState.hoistControllers.clone()
        ..addAll({
          uid: HoistControllerModel(
            uid: uid,
            name:
                '${wayNumber}way Motor Controller #${store.state.fixtureState.hoistControllers.values.where((controller) => controller.ways == wayNumber).length + 1}',
            ways: wayNumber,
          )
        }),
    ));
  };
}

ThunkAction<AppState> selectHoistOutlets(
    UpdateType type, Set<String> hoistIds) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedHoistOutlets(hoistIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(SetSelectedHoistOutlets(
          store.state.navstate.selectedHoistIds.toSet()
            ..addAllIfAbsentElseRemove(hoistIds),
        ));
    }
  };
}

ThunkAction<AppState> selectHoistControllerChannels(
    UpdateType type, Set<String> hoistIds) {
  return (Store<AppState> store) async {
    switch (type) {
      case UpdateType.overwrite:
        store.dispatch(SetSelectedHoistChannelIds(hoistIds));
      case UpdateType.addIfAbsentElseRemove:
        store.dispatch(SetSelectedHoistChannelIds(
          store.state.navstate.selectedHoistChannelIds.toSet()
            ..addAllIfAbsentElseRemove(hoistIds),
        ));
    }
  };
}

ThunkAction<AppState> updateHoistName(String hoistId, String newValue) {
  return (Store<AppState> store) async {
    final hoist = store.state.fixtureState.hoists[hoistId];

    if (hoist == null) {
      return;
    }

    store.dispatch(SetHoists(store.state.fixtureState.hoists.clone()
      ..update(
          hoistId,
          (existing) => existing.copyWith(
                name: newValue.trim(),
              ))));
  };
}

ThunkAction<AppState> deleteHoist(String hoistId) {
  return (Store<AppState> store) async {
    if (hoistId.isEmpty ||
        store.state.fixtureState.hoists.containsKey(hoistId) == false) {
      return;
    }

    store.dispatch(
      SetHoists(
        store.state.fixtureState.hoists.clone()..remove(hoistId),
      ),
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
          otherHoistsInLocation: existingHoistsInLocation, location: location),
      locationId: locationId,
      number: existingHoistsInLocation.length,
      parentController: const HoistControllerChannelAssignment.unassigned(),
      controllerNote: '',
    );

    store.dispatch(SetHoists(store.state.fixtureState.hoists.clone()
      ..addAll({newHoist.uid: newHoist})));
  };
}

ThunkAction<AppState> showLocationOverridesDialog(
    BuildContext context, String locationId) {
  return (Store<AppState> store) async {
    final result = await showDialog(
        context: context,
        fullScreen: true,
        builder: (context) => LocationOverridesDialog(
            initialLocationId: locationId,
            locations: store.state.fixtureState.locations,
            fixtures: store.state.fixtureState.fixtures,
            fixtureTypes: store.state.fixtureState.fixtureTypes,
            globalMaxSequenceBreak: store.state.fixtureState.maxSequenceBreak));

    if (result is Map<String, LocationModel>) {
      store.dispatch(SetLocations(
          Map<String, LocationModel>.from(store.state.fixtureState.locations)
            ..addAll(result)));
    }
  };
}

ThunkAction<AppState> addCablesToLoomAsExtensions(
    BuildContext context, String loomId, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];
    final sourceCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (loom == null ||
        sourceCables.isEmpty ||
        sourceCables.every((cable) => cable.loomId == loom.uid)) {
      return;
    }

    final sourceCableFamilies = CableFamily.createFamilies(sourceCables);

    final extensionCableFamilies = sourceCableFamilies.map((family) {
      if (family.children.isEmpty) {
        // Childless Cable
        return family.copyWith(
            parent: family.parent.copyWith(
          uid: getUid(),
          loomId: loom.uid,
          upstreamId: family.parent.uid,
          parentMultiId: '',
        ));
      } else {
        // Multi Cable with Children.
        final newParentId = getUid();
        return family.copyWith(
          parent: family.parent.copyWith(
            uid: newParentId,
            loomId: loom.uid,
            upstreamId: family.parent.uid,
          ),
          children: family.children
              .map((child) => child.copyWith(
                    uid: getUid(),
                    upstreamId: child.uid,
                    parentMultiId: newParentId,
                    loomId: loom.uid,
                  ))
              .toList(),
        );
      }
    });

    final extensionCables = CableFamily.flattened(extensionCableFamilies);

    store.dispatch(SetCables(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..addAll(extensionCables.toModelMap())));
  };
}

ThunkAction<AppState> updateFixtureDatabaseFilePath(String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureTypeDatabasePath(path));

    await updatePersistentSettings(
        (existing) => existing.copyWith(fixtureTypeDatabasePath: path));
  };
}

ThunkAction<AppState> updateFixtureMappingFilePath(String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureMappingFilePath(path));

    await updatePersistentSettings(
        (existing) => existing.copyWith(fixtureMappingFilePath: path));
  };
}

ThunkAction<AppState> showSetupQuantitiesDialog(BuildContext context) {
  return (Store<AppState> store) async {
    final items = store.state.fixtureState.loomStock.isEmpty
        ? PermanentLoomComposition.buildAllLoomQuantities()
        : store.state.fixtureState.loomStock.values.toList();

    final vms = items
        .map((item) => LoomStockItemViewModel(
            item: item,
            parentComposition:
                PermanentLoomComposition.byName[item.compositionName]!))
        .toList();

    final sortedVms = [
      // Socas
      ...vms
          .where((vm) => vm.parentComposition.socaWays > 0)
          .groupListsBy((vm) => vm.parentComposition.powerWays)
          .values
          .map((group) => [
                ...group,
                LoomStockItemDividerViewModel(),
              ])
          .flattened,

      // 6ways.
      ...vms
          .where((vm) => vm.parentComposition.wieland6Ways > 0)
          .groupListsBy((vm) => vm.parentComposition.powerWays)
          .values
          .map((group) => [
                ...group,
                LoomStockItemDividerViewModel(),
              ])
          .flattened,
    ];

    final result = await showDialog(
        context: context,
        builder: (innerContext) => SetupQuantitiesDialog(items: sortedVms));

    if (result is Map<String, LoomStockModel>) {
      store.dispatch(SetLoomStock(result));
    }
  };
}

ThunkAction<AppState> changeToSpecificComposition(BuildContext context,
    String loomId, PermanentCompositionSelection newSelection) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];
    if (loom == null || newSelection.name.isEmpty) {
      return;
    }

    final concreteComposition =
        PermanentLoomComposition.byName[newSelection.name];

    if (concreteComposition == null) {
      return;
    }

    final existingChildren = store.state.fixtureState.cables.values
        .where((cable) => cable.loomId == loom.uid)
        .where((cable) => newSelection.cutSpares
            ? cable.isSpare == false
            : true) // If user wants to obliterate spares, Filter them out.
        .toList();

    final updatedLoom = loom.copyWith(
        type: loom.type.copyWith(
      permanentComposition: newSelection.name,
      length: concreteComposition.validLengths.contains(loom.type.length)
          ? loom.type.length
          : loom.type.length + 5,
    ));

    final updatedChildren =
        fillCablesToSatisfyPermanentLoom(updatedLoom, existingChildren);

    // If the user has opted to select a Compostion which will involve anihilating the spares, capture those Ids here to be removed.
    final originalSparesToMaybeRemove = newSelection.cutSpares
        ? store.state.fixtureState.cables.values
            .where((cable) => cable.loomId == loom.uid && cable.isSpare == true)
            .map((cable) => cable.uid)
            .toSet()
        : <String>{};

    store.dispatch(SetCablesAndLooms(
      store.state.fixtureState.cables.clone()
        ..addAll(updatedChildren.toModelMap())
        ..removeWhere((key, _) => originalSparesToMaybeRemove.contains(key)),
      store.state.fixtureState.looms.clone()
        ..addAll([updatedLoom].toModelMap()),
    ));
  };
}

ThunkAction<AppState> changeSelectedCablesToDefaultPowerMultiType() {
  return (Store<AppState> store) async {
    final cables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList()
        .where((cable) =>
            cable.type == CableType.socapex ||
            cable.type == CableType.wieland6way);

    if (cables.isEmpty) {
      return;
    }

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(cables
          .map((cable) =>
              cable.copyWith(type: store.state.fixtureState.defaultPowerMulti))
          .toModelMap())));
  };
}

ThunkAction<AppState> switchLoomType(BuildContext context, String loomId) {
  return (Store<AppState> store) async {
    // Queries and Guard Clauses
    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final children = store.state.fixtureState.cables.values
        .where((cable) => cable.loomId == loom.uid)
        .toList();

    if (children.isEmpty) {
      return;
    }

    // Existing Loom is already a Permanent so we are toggling it to a Custom.
    if (loom.type.type == LoomType.permanent) {
      final (updatedCables, updatedLoom) = _convertToCustomLoom(children, loom);

      store.dispatch(SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(updatedCables.toModelMap()),
        store.state.fixtureState.looms.clone()
          ..addAll([updatedLoom].toModelMap()),
      ));
      return;
    }

    // Existing Loom is a Custom so we (attempting) to toggle it to a Permanent.
    final (updatedCables, updatedLoom, error) =
        convertToPermanentLoom(children, loom);

    if (error != null) {
      _showFailedPermanentLoomErrorMessage(context, error);
      return;
    }

    store.dispatch(SetCablesAndLooms(
      store.state.fixtureState.cables.clone()
        ..addAll(updatedCables.toModelMap()),
      store.state.fixtureState.looms.clone()
        ..addAll([updatedLoom].toModelMap()),
    ));
  };
}

void _showFailedPermanentLoomErrorMessage(BuildContext context, String error) {
  showGenericErrorToast(
      context: context,
      title: 'Unable to match suitable Permanent loom',
      extendedMessage: error);
}

(List<CableModel> updatedCables, LoomModel updatedLoom) _convertToCustomLoom(
    List<CableModel> cables, LoomModel loom) {
  // Super easy to go from Permanent to Custom.
  final updatedLoom = loom.copyWith(
      type: loom.type.copyWith(
    type: LoomType.custom,
    permanentComposition: '',
  ));

  // Ensure the Child cables all adopt the original Permanent Looms Length.
  final updatedChildCables = cables
      .map((cable) => cable.copyWith(
            length: updatedLoom.type.length,
          ))
      .toList();

  return (updatedChildCables, updatedLoom);
}

ThunkAction<AppState> reorderLooms(
    BuildContext context, int oldIndex, int newIndex) {
  return (Store<AppState> store) async {
    final newList = store.state.fixtureState.looms.values.toList();
    final movingItem = newList.removeAt(oldIndex);

    if (newIndex > oldIndex) {
      newList.insert(newIndex - 1, movingItem);
    } else {
      newList.insert(newIndex, movingItem);
    }

    store.dispatch(SetLooms(newList.toModelMap()));
  };
}

ThunkAction<AppState> moveCablesIntoLoom(
    BuildContext context, String targetLoomId, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final sourceCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.loomId != targetLoomId)
        .toList();

    if (sourceCables.isEmpty) {
      return;
    }

    final sourceCableIds = sourceCables.map((cable) => cable.uid).toSet();

    final updatedCables = sourceCables.map((cable) {
      if (cable.parentMultiId.isEmpty) {
        return cable.copyWith(loomId: targetLoomId);
      } else if (sourceCableIds.contains(cable.parentMultiId)) {
        // Cable is a child of a Multi parent. But we are moving the multi parent as well.
        // Therefore no special handling is required.
        return cable.copyWith(loomId: targetLoomId);
      } else {
        // Cable is a child of a multi parent.. However we are not moving the parent.
        // Therefore we should emancipate the child from it's parent.
        return cable.copyWith(loomId: targetLoomId, parentMultiId: '');
      }
    }).toList();

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(updatedCables.toModelMap())));
  };
}

ThunkAction<AppState> splitSelectedMultis(BuildContext context) {
  return (Store<AppState> store) async {
    final multiCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where(
          (cable) => cable.isMultiCable,
        );

    if (multiCables.isEmpty) {
      return;
    }

    // Determine if we need to remove any Multi Outlets. This should only be the case when we are removing a Feeder multi.
    final multiIdsToRemove = multiCables
        .where((cable) => cable.upstreamId.isEmpty)
        .map((cable) => cable.outletId)
        .toSet();

    final multiIds = multiCables.map((cable) => cable.uid).toSet();

    final associatedChildren = store.state.fixtureState.cables.values
        .where((cable) => multiIds.contains(cable.parentMultiId));

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(associatedChildren
          .map((child) => child.copyWith(parentMultiId: ''))
          .toModelMap())
      ..removeWhere((key, value) => multiIds.contains(key))));

    if (multiIdsToRemove.isNotEmpty) {
      store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
        ..removeWhere((key, _) => multiIdsToRemove.contains(key))));

      store.dispatch(SetHoistMultis(store.state.fixtureState.hoistMultis.clone()
        ..removeWhere((key, _) => multiIdsToRemove.contains(key))));
    }
  };
}

ThunkAction<AppState> combineSelectedCablesIntoMultis(BuildContext context) {
  return (Store<AppState> store) async {
    final validCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) =>
            cable.type == CableType.dmx || cable.type == CableType.hoist)
        .toList();

    final allOutlets = [
      ...store.state.fixtureState.dataMultis.values,
      ...store.state.fixtureState.powerMultiOutlets.values,
      ...store.state.fixtureState.dataPatches.values,
      ...store.state.fixtureState.hoists.values,
      ...store.state.fixtureState.hoistMultis.values,
    ].toModelMap();

    final sneakCombinationResult = combineDmxIntoSneak(
        cables: validCables,
        outlets: allOutlets,
        existingLocations: store.state.fixtureState.locations,
        reusableSneaks: validCables
            .map((cable) => cable.parentMultiId)
            .map((sneakId) => store.state.fixtureState.cables[sneakId])
            .nonNulls
            .where((cable) => cable.type == CableType.sneak)
            .toList());

    final hoistMultiCombinationResult = combineHoistsIntoMulti(
        cables: validCables,
        outlets: allOutlets,
        existingLocations: store.state.fixtureState.locations.clone()
          ..addAll(sneakCombinationResult.locations.toModelMap()),
        reusableMultis: validCables
            .map((cable) => cable.parentMultiId)
            .map((sneakId) => store.state.fixtureState.cables[sneakId])
            .nonNulls
            .where((cable) => cable.type == CableType.hoistMulti)
            .toList());

    store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
      ..addAll([
        ...sneakCombinationResult.locations,
        ...hoistMultiCombinationResult.locations,
      ].toModelMap())));

    store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
      ..addAll(sneakCombinationResult.newDataMultis.toModelMap())));

    store.dispatch(SetHoistMultis(store.state.fixtureState.hoistMultis.clone()
      ..addAll(hoistMultiCombinationResult.newHoistMultis.toModelMap())));

    final cableIdsToRemove = [
      ...sneakCombinationResult.cablesToDelete,
      ...hoistMultiCombinationResult.cablesToDelete,
    ].map((cable) => cable.uid).toSet();

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll([
            ...sneakCombinationResult.cables,
            ...hoistMultiCombinationResult.cables
          ].toModelMap())
          ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
      ),
    );

    store.dispatch(SetSelectedCableIds(
        sneakCombinationResult.cables.map((cable) => cable.uid).toSet()));
  };
}

ThunkAction<AppState> createNewLoomFromExistingCables(
    BuildContext context,
    List<String> cableIds,
    int insertIndex,
    Set<CableActionModifier> modifiers) {
  return (Store<AppState> store) async {
    final newLoomId = getUid();

    final updatedCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .map((cable) => cable.copyWith(
              loomId: newLoomId,
            ))
        .toList();

    if (updatedCables.isEmpty) {
      return;
    }

    final associatedLocations = extractLocationsFromOutlets(
        updatedCables
            .map((cable) => cable.outletId)
            .map((outletId) => [
                  store.state.fixtureState.powerMultiOutlets[outletId],
                  store.state.fixtureState.dataMultis[outletId],
                  store.state.fixtureState.dataPatches[outletId],
                  store.state.fixtureState.hoists[outletId],
                  store.state.fixtureState.hoistMultis[outletId],
                ])
            .flattened
            .nonNulls
            .toList(),
        store.state.fixtureState.locations);

    final newLoom = LoomModel(
      uid: newLoomId,
      type: LoomTypeModel(
          length: updatedCables.first.length, type: LoomType.custom),
      name: determineDefaultLoomName(
          associatedPrimaryLocation: associatedLocations.first,
          children: updatedCables,
          existingLooms: store.state.fixtureState.looms,
          existingOutlets: selectAllOutlets(store),
          existingCables: store.state.fixtureState.cables),
    );

    final actionModifierResult = applyCableActionModifiers(
      modifiers: modifiers,
      cables: updatedCables.toModelMap(),
      dataMultis: store.state.fixtureState.dataMultis,
      hoistMultis: store.state.fixtureState.hoistMultis,
      locations: store.state.fixtureState.locations,
      loom: newLoom,
      outlets: [
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.dataPatches.values,
        ...store.state.fixtureState.hoists.values,
        ...store.state.fixtureState.hoistMultis.values,
      ].toModelMap(),
    );

    _performPostCableActionModifierDispatches(
        context, store, actionModifierResult);

    store.dispatch(SetCablesAndLooms(
      store.state.fixtureState.cables.clone()
        ..addAll(actionModifierResult.cables),
      store.state.fixtureState.looms.copyWithInsertedEntry(
          (insertIndex - 1).clamp(0, 99999),
          convertToMapEntry(actionModifierResult.loom)),
    ));

    store.dispatch(SetSelectedCableIds(
      updatedCables.map((cable) => cable.uid).toSet(),
    ));
  };
}

ThunkAction<AppState> createNewFeederLoom(
    BuildContext context,
    List<String> outletIds,
    int insertIndex,
    Set<CableActionModifier> modifiers) {
  return (Store<AppState> store) async {
    final newLoomId = getUid();

    // Create corresponding Cables for Each outlet.
    final dataOutlets = outletIds
        .map((id) => store.state.fixtureState.dataPatches[id])
        .nonNulls;
    final powerMultiOutlets = outletIds
        .map((id) => store.state.fixtureState.powerMultiOutlets[id])
        .nonNulls;
    final hoistOutlets =
        outletIds.map((id) => store.state.fixtureState.hoists[id]).nonNulls;

    final associatedLocations = extractLocationsFromOutlets(
        [...dataOutlets, ...powerMultiOutlets, ...hoistOutlets],
        store.state.fixtureState.locations);

    final targetLength = associatedLocations
        .map(
            (location) => location.color.colors.firstOrNull?.defaultLength ?? 0)
        .sorted((a, b) => a.floor() - b.floor())
        .last;

    final List<CableModel> newCables = [
      ...powerMultiOutlets.map((outlet) => CableModel(
            uid: getUid(),
            outletId: outlet.uid,
            type: store.state.fixtureState.defaultPowerMulti,
            loomId: newLoomId,
            length: targetLength,
          )),
      ...dataOutlets.map((outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.dmx,
          length: targetLength,
          loomId: newLoomId)),
      ...hoistOutlets.map((outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.hoist,
          length: targetLength,
          loomId: newLoomId))
    ];

    final newLoom = LoomModel(
      uid: newLoomId,
      type: LoomTypeModel(length: targetLength, type: LoomType.custom),
      name: determineDefaultLoomName(
          associatedPrimaryLocation: associatedLocations.first,
          children: newCables,
          existingLooms: store.state.fixtureState.looms,
          existingOutlets: selectAllOutlets(store),
          existingCables: store.state.fixtureState.cables),
    );

    final actionModifierResult = applyCableActionModifiers(
      modifiers: modifiers,
      cables: newCables.toModelMap(),
      dataMultis: store.state.fixtureState.dataMultis,
      hoistMultis: store.state.fixtureState.hoistMultis,
      locations: store.state.fixtureState.locations,
      loom: newLoom,
      outlets: [
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.dataPatches.values,
        ...store.state.fixtureState.hoists.values,
        ...store.state.fixtureState.hoistMultis.values,
      ].toModelMap(),
    );

    _performPostCableActionModifierDispatches(
        context, store, actionModifierResult);

    store.dispatch(SetCablesAndLooms(
      store.state.fixtureState.cables.clone()
        ..addAll(actionModifierResult.cables),
      store.state.fixtureState.looms.copyWithInsertedEntry(
          (insertIndex - 1).clamp(0, 99999),
          convertToMapEntry(actionModifierResult.loom)),
    ));

    store.dispatch(SetSelectedCableIds(
      newCables.map((cable) => cable.uid).toSet(),
    ));
  };
}

void _performPostCableActionModifierDispatches(BuildContext context,
    Store<AppState> store, CableActionModifierResult actionModifierResult) {
  if (actionModifierResult.permanentLoomConversionError != null) {
    _showFailedPermanentLoomErrorMessage(
        context, actionModifierResult.permanentLoomConversionError!);
  }

  if (store.state.fixtureState.locations != actionModifierResult.locations) {
    store.dispatch(SetLocations(actionModifierResult.locations));
  }

  if (store.state.fixtureState.dataMultis != actionModifierResult.dataMultis) {
    store.dispatch(SetDataMultis(actionModifierResult.dataMultis));
  }

  if (store.state.fixtureState.hoistMultis !=
      actionModifierResult.hoistMultis) {
    store.dispatch(SetHoistMultis(actionModifierResult.hoistMultis));
  }
}

ThunkAction<AppState> createNewExtensionLoom(BuildContext context,
    List<String> cableIds, int index, Set<CableActionModifier> modifiers) {
  return (Store<AppState> store) async {
    final cables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (cables.isEmpty) {
      return;
    }

    final longestCable = cables
        .map((cable) => cable.length)
        .sorted((a, b) => a.floor() - b.floor())
        .last;

    final outlets = selectAllOutlets(store);

    final associatedLocations = extractLocationsFromOutlets(
      cables.map((cable) => outlets[cable.outletId]).nonNulls.toList(),
      store.state.fixtureState.locations,
    );

    LoomModel newLoom = LoomModel(
      uid: getUid(),
      type: LoomTypeModel(length: longestCable, type: LoomType.custom),
    );

    final cableFamilies = CableFamily.createFamilies(cables);

    final clonedFamilies = cableFamilies.map((family) {
      if (family.children.isEmpty) {
        // Standard Cable
        return family.copyWith(
            parent: family.parent.copyWith(
          uid: getUid(),
          upstreamId: family.parent.uid,
          parentMultiId:
              '', // Remove the cable from it's existing parent. This ensures we can drag a child cable from an existing loom and create and new loom from it.
          loomId: newLoom.uid,
        ));
      } else {
        // Multi Cable with Children.
        final clonedParent = family.parent.copyWith(
          uid: getUid(),
          upstreamId: family.parent.uid,
          loomId: newLoom.uid,
        );

        return family.copyWith(
          parent: clonedParent,
          children: family.children
              .map((child) => child.copyWith(
                    uid: getUid(),
                    parentMultiId: clonedParent.uid,
                    upstreamId: child.uid,
                    loomId: newLoom.uid,
                  ))
              .toList(),
        );
      }
    });

    final clonedCables = CableFamily.flattened(clonedFamilies);

    newLoom = newLoom.copyWith(
      name: determineDefaultLoomName(
        associatedPrimaryLocation: associatedLocations.first,
        children: clonedCables,
        existingLooms: store.state.fixtureState.looms,
        existingOutlets: selectAllOutlets(store),
        existingCables: store.state.fixtureState.cables,
      ),
    );

    final actionModifierResult = applyCableActionModifiers(
      modifiers: modifiers,
      cables: store.state.fixtureState.cables.clone()
        ..addAll(clonedCables.toModelMap()),
      dataMultis: store.state.fixtureState.dataMultis,
      hoistMultis: store.state.fixtureState.hoistMultis,
      locations: store.state.fixtureState.locations,
      loom: newLoom,
      outlets: [
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.dataPatches.values,
        ...store.state.fixtureState.hoists.values,
        ...store.state.fixtureState.hoistMultis.values,
      ].toModelMap(),
    );

    _performPostCableActionModifierDispatches(
        context, store, actionModifierResult);

    store.dispatch(SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(actionModifierResult.cables),
        store.state.fixtureState.looms.copyWithInsertedEntry(
            (index - 1).clamp(0, 99999),
            convertToMapEntry(actionModifierResult.loom))));

    store.dispatch(SetSelectedCableIds(
      actionModifierResult.cables.values
          .where((cable) => cable.loomId == newLoom.uid)
          .map((cable) => cable.uid)
          .toSet(),
    ));
  };
}

ThunkAction<AppState> showImportManager(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await showDialog(
        context: context,
        builder: (innerContext) => const ImportManagerContainer());

    if (result is ImportManagerResult) {
      store.dispatch(SetImportedFixtureData(
          fixtures: result.fixtures.toModelMap(),
          locations: result.locations.toModelMap(),
          fixtureTypes: result.fixtureTypes.toModelMap()));

      if (context.mounted) {
        showGenericSuccessToast(context: context, title: "Patch imported.");
      }
    } else {
      store.dispatch(SetImportManagerStep(ImportManagerStep.fileSelect));
    }
  };
}

ThunkAction<AppState> chooseExportDirectory(BuildContext context) {
  return (Store<AppState> store) async {
    final lastUsedExportDirectory =
        store.state.fileState.projectMetadata.lastUsedExportDirectory.isNotEmpty
            ? store.state.fileState.projectMetadata.lastUsedExportDirectory
            : store.state.fileState.lastUsedProjectDirectory;

    final lastUsedExportDirectoryExists =
        await Directory(lastUsedExportDirectory).exists();

    final pathResult = await getDirectoryPath(
        initialDirectory:
            lastUsedExportDirectoryExists && lastUsedExportDirectory.isNotEmpty
                ? lastUsedExportDirectory
                : null);

    if (pathResult == null) {
      return;
    }

    store.dispatch(SetLastUsedExportDirectory(pathResult));
  };
}

ThunkAction<AppState> changeExistingPowerMultisToDefault(BuildContext context) {
  return (Store<AppState> store) async {
    final targetValue = store.state.fixtureState.defaultPowerMulti;
    final existingValue = targetValue == CableType.socapex
        ? CableType.wieland6way
        : CableType.socapex;

    final updatedCables = store.state.fixtureState.cables.clone()
      ..updateAll((_, existingCable) => existingCable.type == existingValue
          ? existingCable.copyWith(type: targetValue)
          : existingCable);

    String permanentCompositionNameSwitcher(String value) =>
        targetValue == CableType.socapex
            ? value.replaceAll(kWielandSlug, kSocaSlug)
            : value.replaceAll(kSocaSlug, kWielandSlug);

    final keyword =
        existingValue == CableType.socapex ? kSocaSlug : kWielandSlug;
    final updatedLooms = store.state.fixtureState.looms.clone()
      ..updateAll(
        (_, existingLoom) =>
            existingLoom.type.permanentComposition.contains(keyword)
                ? existingLoom.copyWith(
                    type: existingLoom.type.copyWith(
                        permanentComposition: permanentCompositionNameSwitcher(
                            existingLoom.type.permanentComposition)))
                : existingLoom,
      );

    store.dispatch(SetCablesAndLooms(
      updatedCables,
      updatedLooms,
    ));
  };
}

ThunkAction<AppState> repairLoomComposition(
    LoomModel loom, BuildContext context) {
  return (Store<AppState> store) async {
    final parentCables = store.state.fixtureState.cables.values
        .where(
            (cable) => cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
        .toList();

    // Attempt a simple repair first.
    final firstRunCompositionResult =
        PermanentLoomComposition.matchSuitablePermanent(parentCables);

    if (firstRunCompositionResult.error == null) {
      store.dispatch(
        SetCablesAndLooms(
          // Cables
          store.state.fixtureState.cables.clone()
            ..addAll(_generateSpareCablesToMeetComposition(
                    loom, parentCables, firstRunCompositionResult.composition)
                .toModelMap()),
          // Looms
          store.state.fixtureState.looms.clone()
            ..update(
              loom.uid,
              (_) => loom.copyWith(
                type: loom.type.copyWith(
                    permanentComposition:
                        firstRunCompositionResult.composition.name),
              ),
            ),
        ),
      );
      return;
    }

    if (homeScaffoldKey.currentContext != null &&
        homeScaffoldKey.currentContext!.mounted) {
      showGenericErrorToast(
          context: context,
          title: "Composition repair failed",
          subtitle:
              "Unable to auto repair composition. Try combining DMX into Sneak or convert to a custom loom",
          extendedMessage: firstRunCompositionResult.error);
    }
  };
}

List<CableModel> _generateSpareCablesToMeetComposition(
    LoomModel existingLoom,
    List<CableModel> existingParentCablesInLoom,
    PermanentLoomComposition targetComposition) {
  // Create any Spare cables if we have to in order to reach the desired composition.
  final cablesByType =
      existingParentCablesInLoom.groupListsBy((cable) => cable.type);
  final neededSocaWays = targetComposition.socaWays -
      (cablesByType[CableType.socapex]?.length ?? 0).clamp(0, 100);
  final neededWielandWays = targetComposition.wieland6Ways -
      (cablesByType[CableType.wieland6way]?.length ?? 0).clamp(0, 100);
  final neededSneakWays = targetComposition.sneakWays -
      (cablesByType[CableType.sneak]?.length ?? 0).clamp(0, 100);
  final neededDmxWays = targetComposition.dmxWays -
      (cablesByType[CableType.dmx]?.length ?? 0).clamp(0, 100);

  final existingSpareCablesByType = cablesByType.map((key, value) =>
      MapEntry(key, value.where((cable) => cable.isSpare == true).toList()));

  List<CableModel> generateSpares(int qty, CableType type) =>
      List<CableModel>.generate(
          qty,
          (index) => CableModel(
                uid: getUid(),
                loomId: existingLoom.uid,
                type: type,
                length: existingLoom.type.length,
                isSpare: true,
                spareIndex: (index + 1) +
                    (existingSpareCablesByType[type]?.length ?? 0),
              ));

  return [
    ...generateSpares(neededSocaWays, CableType.socapex),
    ...generateSpares(neededWielandWays, CableType.wieland6way),
    ...generateSpares(neededSneakWays, CableType.sneak),
    ...generateSpares(neededDmxWays, CableType.dmx),
  ];
}

ThunkAction<AppState> setSelectedCableIds(Set<String> ids) {
  return (Store<AppState> store) async {
    final cables =
        ids.map((id) => store.state.fixtureState.cables[id]).nonNulls.toList();

    // If we have selected any Parent Multi cable, select all it's children as well.
    final withChildCables = cables.expand((cable) => cable.isMultiCable
        ? [
            // Parent Multi Cable
            cable,

            // It's Children.
            ...store.state.fixtureState.cables.values
                .where((child) => child.parentMultiId == cable.uid)
          ]
        : [cable]);

    store.dispatch(
        SetSelectedCableIds(withChildCables.map((cable) => cable.uid).toSet()));
  };
}

ThunkAction<AppState> deleteSelectedCables(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    final sneaks =
        selectedCables.where((cable) => cable.type == CableType.sneak);

    final hoistMultis =
        selectedCables.where((cable) => cable.type == CableType.hoistMulti);

    final selectedCablesWithChildren = [
      ...selectedCables,
      ...sneaks.expand((sneak) => store.state.fixtureState.cables.values
          .where((cable) => cable.parentMultiId == sneak.uid)),
      ...hoistMultis.expand((multi) => store.state.fixtureState.cables.values
          .where((cable) => cable.parentMultiId == multi.uid))
    ];

    final cableIdsToRemove =
        selectedCablesWithChildren.map((cable) => cable.uid).toSet();

    // Select DataMultiOutlet Ids to remove. We predicate this on if their are no other cables (ie extensions) that are
    // dependenent on that outlet.
    final dataMultiIdsToRemove = sneaks
        .map((sneak) {
          final otherSneakCablesWithSameOutlet =
              store.state.fixtureState.cables.values.where((cable) =>
                  cable.outletId == sneak.outletId && cable.uid != sneak.uid);

          return otherSneakCablesWithSameOutlet.isEmpty ? sneak.outletId : null;
        })
        .nonNulls
        .toSet();

    // Select Hoist Multi Outlets Ids to remove. We predicate this on if their are no other cables (ie extensions) that are
    // dependenent on that outlet.
    final hoistMultiIdsToRemove = hoistMultis
        .map((multi) {
          final otherHoistMultisWithSameOutlet =
              store.state.fixtureState.cables.values.where((cable) =>
                  cable.outletId == multi.outletId && cable.uid != multi.uid);

          return otherHoistMultisWithSameOutlet.isEmpty ? multi.outletId : null;
        })
        .nonNulls
        .toSet();

    store.dispatch(SetCables(assertMultiChildSpares(
        store.state.fixtureState.cables.clone()
          ..removeWhere((key, value) => cableIdsToRemove.contains(key)))));

    if (dataMultiIdsToRemove.isNotEmpty) {
      store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
        ..removeWhere((key, __) => dataMultiIdsToRemove.contains(key))));
    }

    if (hoistMultiIdsToRemove.isNotEmpty) {
      store.dispatch(SetHoistMultis(store.state.fixtureState.hoistMultis.clone()
        ..removeWhere((key, _) => hoistMultiIdsToRemove.contains(key))));
    }
  };
}

ThunkAction<AppState> addSpareCablesToLoom(
    BuildContext context, String loomId) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final result = await openShadSheet(
        context: context,
        builder: (context) => AddSpareCables(
              defaultPowerMultiType: store.state.fixtureState.defaultPowerMulti,
            ));

    if (result == null) {
      return;
    }

    if (result is AddSpareCablesResult) {
      final values = result.values;

      // Expand the values from the Dialog into a List of CableTypes. This makes it easier to reduce
      // these values later on.
      final expandedTypes = values.expand((value) =>
          List<CableType>.generate(value.qty, (index) => value.type));

      final existingCablesInLoom = store.state.fixtureState.cables.values
          .where((cable) => cable.loomId == loomId);

      final updatedCables = expandedTypes.fold<List<CableModel>>(
          existingCablesInLoom.toList(), (cablesInLoom, type) {
        final existingCablesOfType =
            cablesInLoom.where((cable) => cable.type == type);

        final existingParentSparesOfType = existingCablesOfType
            .where(
                (cable) => cable.isSpare == true && cable.parentMultiId.isEmpty)
            .toList();

        final newParentCable = CableModel(
          uid: getUid(),
          type: type,
          isSpare: true,
          loomId: loomId,
          length: existingParentSparesOfType.firstOrNull?.length ??
              existingCablesOfType.firstOrNull?.length ??
              cablesInLoom.firstOrNull?.length ??
              0,
          spareIndex: _selectNextSpareIndex(existingParentSparesOfType),
        );

        return [
          ...cablesInLoom,
          newParentCable,

          // Optionally create 4 children if current cable is a Sneak.
          if (type == CableType.sneak)
            ...List<CableModel>.generate(
                4,
                (index) => CableModel(
                    uid: getUid(),
                    type: CableType.dmx,
                    loomId: loomId,
                    isSpare: true,
                    parentMultiId: newParentCable.uid,
                    length: newParentCable.length,
                    spareIndex: index)),
        ];
      });

      store.dispatch(
        SetCables(
          store.state.fixtureState.cables.clone()
            ..addAll(updatedCables.toModelMap()),
        ),
      );

      store.dispatch(SetSelectedCableIds(
        updatedCables
            .where((cable) => cable.isSpare)
            .map((cable) => cable.uid)
            .toSet(),
      ));
    }
  };
}

int _selectNextSpareIndex(List<CableModel> spareCables) {
  if (spareCables.isEmpty) {
    return 0;
  }

  int highestSpareIndex = 1;
  for (final cable in spareCables) {
    highestSpareIndex = highestSpareIndex < cable.spareIndex
        ? cable.spareIndex
        : highestSpareIndex;
  }

  return highestSpareIndex;
}

ThunkAction<AppState> addOutletsToLoom(
    BuildContext context, String loomId, Set<String> outletIds) {
  return (Store<AppState> store) async {
    if (outletIds.isEmpty) {
      return;
    }

    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final outlets = selectOutlets(outletIds, store);

    final newCables = [
      ...outlets.powerOutlets.map((outlet) => CableModel(
            uid: getUid(),
            outletId: outlet.uid,
            type: store.state.fixtureState.defaultPowerMulti,
            length: loom.type.length,
            loomId: loom.uid,
          )),
      ...outlets.dataOutlets.map((outlet) => CableModel(
            uid: getUid(),
            outletId: outlet.uid,
            type: CableType.dmx,
            length: loom.type.length,
            loomId: loom.uid,
          )),
      ...outlets.hoistOutlets.map((outlet) => CableModel(
            uid: getUid(),
            outletId: outlet.uid,
            type: CableType.hoist,
            length: loom.type.length,
            loomId: loom.uid,
          ))
    ];

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(newCables.toModelMap())));

    return;
  };
}

ThunkAction<AppState> deleteLoom(BuildContext context, String uid) {
  return (Store<AppState> store) async {
    if (uid.isEmpty) {
      return;
    }

    final loom = store.state.fixtureState.looms[uid];

    if (loom == null) {
      return;
    }

    final allChildCables = store.state.fixtureState.cables.values
        .where((cable) => cable.loomId == loom.uid)
        .toList();

    // If we are deleting any Sneaks, we will also need to delete their corresponding DataMutliOutlet, predicated on if there
    // are no other sneaks which are dependent on that outlet.
    final dataMultiIdsToRemove = allChildCables
        .where((cable) =>
            cable.type == CableType.sneak &&
            store.state.fixtureState.cables.values
                .where((other) =>
                    other.outletId == cable.outletId && other.uid != cable.uid)
                .isEmpty)
        .map((cable) => cable.outletId)
        .toSet();

    // As Above we need to remove any Hoist Multis.
    final hoistMultiIdsToRemove = allChildCables
        .where((cable) =>
            cable.type == CableType.hoistMulti &&
            store.state.fixtureState.cables.values
                .where((other) =>
                    other.outletId == cable.outletId && other.uid != cable.uid)
                .isEmpty)
        .map((cable) => cable.outletId)
        .toSet();

    final cableIdsToRemove = allChildCables.map((cable) => cable.uid).toSet();

    // Delete Cables and Loom
    store.dispatch(SetCablesAndLooms(
      store.state.fixtureState.cables.clone()
        ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
      store.state.fixtureState.looms.clone()..remove(loom.uid),
    ));

    // Optionally remove any corresponding DataMulti Outlets.
    if (dataMultiIdsToRemove.isNotEmpty) {
      store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
        ..removeWhere((key, value) => dataMultiIdsToRemove.contains(key))));
    }

    // Optionally remove any corresponding Hoist Multi outlets.
    if (hoistMultiIdsToRemove.isNotEmpty) {
      store.dispatch(SetHoistMultis(store.state.fixtureState.hoistMultis.clone()
        ..removeWhere((key, __) => hoistMultiIdsToRemove.contains(key))));
    }

    store.dispatch(SetSelectedCableIds({}));
  };
}

ThunkAction<AppState> debugButtonPressed() {
  return (Store<AppState> store) async {
    print("No Action Performed");
  };
}

ThunkAction<AppState> initializeApp(BuildContext context) {
  return (Store<AppState> store) async {
    // Fetch Persistent Settings.
    await initPersistentSettingsStorage();
    final persistentSettings = await fetchPersistentSettings();

    // Set the Fixture Database Path value, and load the Fixture Database if we can.
    if (persistentSettings.fixtureTypeDatabasePath.isNotEmpty) {
      store.dispatch(
        SetFixtureTypeDatabasePath(persistentSettings.fixtureTypeDatabasePath),
      );
    }

    // Load the Fixture Mapping Path.
    if (persistentSettings.fixtureMappingFilePath.isNotEmpty) {
      store.dispatch(
          SetFixtureMappingFilePath(persistentSettings.fixtureMappingFilePath));
    }
  };
}

ThunkAction<AppState> startNewProject(BuildContext context, bool saveCurrent) {
  return (Store<AppState> store) async {
    if (saveCurrent) {
      store.dispatch(saveProjectFile(context, SaveType.save));
    }

    store.dispatch(NewProject());

    diffAppStore.dispatch(NewProject());
  };
}

ThunkAction<AppState> openProjectFile(
    BuildContext context, bool saveCurrent, String path) {
  return (Store<AppState> store) async {
    final projectFile = await deserializeProjectFile(path);

    store.dispatch(OpenProject(
      project: projectFile,
      parentDirectory: p.dirname(path),
      path: path,
    ));

    // Reset the Diff App State.
    if (store is! Store<DiffAppState>) {
      diffAppStore.dispatch(NewProject());
    }
  };
}

ThunkAction<AppState> saveProjectFile(BuildContext context, SaveType saveType) {
  return (Store<AppState> store) async {
    final saveAsNeeded = store.state.fileState.projectFilePath.isEmpty ||
        saveType == SaveType.saveAs;

    String targetFilePath = store.state.fileState.projectFilePath;

    // If a save as is required, collect the new File path and store it to target File Path.
    if (saveAsNeeded == true) {
      // Post a dialog to collect the new file location.
      final selectedFilePath = await getSaveLocation(
        acceptedTypeGroups: kProjectFileTypes,
        initialDirectory:
            await Directory(store.state.fileState.lastUsedProjectDirectory)
                    .exists()
                ? store.state.fileState.lastUsedProjectDirectory
                : null,
        confirmButtonText: 'Save As',
      );

      if (selectedFilePath == null || selectedFilePath.path.isEmpty) {
        return;
      }

      targetFilePath = selectedFilePath.path;
    }

    try {
      // Ensure the file path contains the correct extension.
      if (p.extension(targetFilePath).trim() != '.$kProjectFileExtension') {
        targetFilePath = '$targetFilePath.$kProjectFileExtension';
      }

      // Perform the File Operations.
      var newMetadata = await serializeProjectFile(store.state, targetFilePath);

      // Save the updated Metadata.
      store.dispatch(SetProjectFileMetadata(newMetadata));
      store.dispatch(SetLastUsedProjectDirectory(p.dirname(targetFilePath)));
      store.dispatch(SetProjectFilePath(targetFilePath));

      if (context.mounted) {
        showFileSaveSuccessToast(context: context);
      }
    } catch (e) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'An error occured.',
            subtitle: 'Project saving failed.',
            extendedMessage: e.toString());
      }
    }
  };
}

String getTestDataPath() {
  const String testDataDirectory = './test_data/';
  const String testFileName = 'fixtures.xlsx';
  final String testDataPath = p.join(testDataDirectory, testFileName);
  return testDataPath;
}

ThunkAction<AppState> updateLocationMultiPrefix(
    String locationId, String newValue) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation = existingLocation.copyWith(multiPrefix: newValue);

    store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
      ..update(locationId, (_) => updatedLocation)));
  };
}

ThunkAction<AppState> updateLocationMultiDelimiter(
    String locationId, String newValue) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation = existingLocation.copyWith(delimiter: newValue);

    store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
      ..update(locationId, (_) => updatedLocation)));
  };
}

ThunkAction<AppState> rangeSelectFixtures(
    String startUid, String endUid, bool isAdditive) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();

    if (fixtures.isEmpty) {
      return;
    }

    if (fixtures.length == 1 || startUid == endUid) {
      store.dispatch(SetSelectedFixtureIds({startUid}));
      return;
    }

    final rawStartIndex =
        fixtures.indexWhere((fixture) => fixture.uid == startUid);
    final rawEndIndex = fixtures.indexWhere((fixture) => fixture.uid == endUid);

    if (rawStartIndex == -1 || rawEndIndex == -1) {
      return;
    }

    final (coercedStartIndex, coercedEndIndex) = rawStartIndex > rawEndIndex
        ? (rawEndIndex, rawStartIndex)
        : (rawStartIndex, rawEndIndex);

    final ids = fixtures
        .sublist(coercedStartIndex,
            coercedEndIndex + 1 <= fixtures.length ? coercedEndIndex + 1 : null)
        .map((fixture) => fixture.uid)
        .toSet();

    if (isAdditive) {
      ids.addAll(store.state.navstate.selectedFixtureIds);
    }

    // Optionally reverse the collection if the Range Selection itself was inverted.
    store.dispatch(SetSelectedFixtureIds(
        rawStartIndex > rawEndIndex ? ids.toList().reversed.toSet() : ids));
  };
}

ThunkAction<AppState> setSequenceNumbers(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedFixtures = store.state.navstate.selectedFixtureIds
        .map((id) => store.state.fixtureState.fixtures[id]!)
        .toList();

    final result = await showDialog(
      context: context,
      builder: (context) => SequencerDialog(
          fixtures: selectedFixtures,
          fixtureTypes: store.state.fixtureState.fixtureTypes,
          nextAvailableSequenceNumber: _findNextAvailableSequenceNumber(
              selectedFixtures.map((fix) => fix.sequence).toList())),
    );

    if (result == null) {
      return;
    }

    if (result is Map<int, FixtureModel>) {
      final existingFixtures = store.state.fixtureState.fixtures.clone();

      for (final entry in result.entries) {
        final newSeqNumber = entry.key;
        final fixtureId = entry.value.uid;

        existingFixtures.update(
            fixtureId, (fixture) => fixture.copyWith(sequence: newSeqNumber));
      }

      final sortedFixtures = FixtureModel.sort(
          existingFixtures, store.state.fixtureState.locations);

      store.dispatch(SetFixtures(sortedFixtures));
    }
  };
}

ThunkAction<AppState> export(BuildContext context) {
  return (Store<AppState> store) async {
    final outputPaths = ExportFilePaths(
        directoryPath:
            store.state.fileState.projectMetadata.lastUsedExportDirectory,
        projectName: store.state.fileState.projectMetadata.projectName,
        excelFileExtension: '.xlsx');

    if (await outputPaths.parentDirectoryExists == false) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Parent Directory could not be found',
            subtitle: 'Have you selected an export directory?');
      }
      return;
    }

    final existingFileNames = await outputPaths.getAlreadyExistingFileNames();

    if (existingFileNames.isNotEmpty) {
      if (context.mounted) {
        final dialogResult = await showGenericDialog(
          context: context,
          title: 'Overwrite existing files',
          message:
              'If you proceed, the following files will be overwritten.\n${existingFileNames.join('\n')}',
          affirmativeText: 'Overwrite',
          destructiveAffirmative: true,
          declineText: 'Cancel',
        );

        if (dialogResult == null || dialogResult == false) {
          return;
        }
      }
    }

    final referenceDataExcel = Excel.createExcel();
    createPowerPatchSheet(
      excel: referenceDataExcel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
    );

    createColorLookupSheet(
      excel: referenceDataExcel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
    );

    createFixtureTypeValidationSheet(
      excel: referenceDataExcel,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
    );

    createDataPatchSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches.values,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
    );

    createDataMultiSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
      dataMultis: store.state.fixtureState.dataMultis,
    );

    referenceDataExcel.delete('Sheet1');

    final loomsExcel = Excel.createExcel();

    createLoomsSheet(
      excel: loomsExcel,
      store: store,
    );

    loomsExcel.delete('Sheet1');

    final addressingExcel = Excel.createExcel();

    createFixtureAddressingSheet(
      fixtures: store.state.fixtureState.fixtures.values.toList(),
      locations: store.state.fixtureState.locations,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      excel: addressingExcel,
      projectName: store.state.fileState.projectMetadata.projectName,
    );

    final fixtureInfoExcel = Excel.createExcel();

    createFixtureInfoSheet(
      fixtures: store.state.fixtureState.fixtures.values.toList(),
      locations: store.state.fixtureState.locations,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      excel: fixtureInfoExcel,
      projectName: store.state.fileState.projectMetadata.projectName,
    );

    final hoistPatchExcel = Excel.createExcel();

    createHoistPatchSheet(excel: hoistPatchExcel, store: store);
    hoistPatchExcel.delete('Sheet1');

    final referenceDataBytes = referenceDataExcel.save();
    final loomsBytes = loomsExcel.save();
    final powerPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_power_patch.xlsx');
    final dataPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_data_patch.xlsx');
    final addressingBytes = addressingExcel.save();
    final fixtureInfoBytes = fixtureInfoExcel.save();
    final hoistPatchBytes = hoistPatchExcel.save();

    if (referenceDataBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Excel output error',
            subtitle: 'An error occurred writing reference data');
      }

      return;
    }

    if (loomsBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Excel output error',
            subtitle: 'An error occurred writing looms data');
      }

      return;
    }

    if (hoistPatchBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Excel output error',
            subtitle: 'An error occurred writing hoist data');
      }

      return;
    }

    if (addressingBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Excel output error',
            subtitle: 'An error occurred writing fixture addressing data');
      }

      return;
    }

    if (fixtureInfoBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Excel output error',
            subtitle: 'An error occurred writing fixture info data');
      }

      return;
    }

    final fileWrites = [
      File(outputPaths.referenceDataPath).writeAsBytes(referenceDataBytes),
      File(outputPaths.loomsPath).writeAsBytes(loomsBytes),
      File(outputPaths.powerPatchPath)
          .writeAsBytes(powerPatchTemplateBytes.buffer.asUint8List()),
      File(outputPaths.dataPatchPath)
          .writeAsBytes(dataPatchTemplateBytes.buffer.asUint8List()),
      File(outputPaths.addressesPath).writeAsBytes(addressingBytes),
      File(outputPaths.fixtureInfoPath).writeAsBytes(fixtureInfoBytes),
      File(outputPaths.hoistPatchPath).writeAsBytes(hoistPatchBytes),
    ];

    try {
      await Future.wait(fileWrites);
    } catch (e) {
      if (context.mounted) {
        showGenericErrorToast(
            context: context,
            title: 'Export error',
            subtitle: '1 or more files failed to export');

        return;
      }
    }

    if (context.mounted) {
      showGenericSuccessToast(
          context: context, title: 'Export finished successfully');
    }

    if (store.state.navstate.openAfterExport == true) {
      await launchUrl(Uri.file(outputPaths.powerPatchPath));
      await launchUrl(Uri.file(outputPaths.dataPatchPath));
      await launchUrl(Uri.file(outputPaths.loomsPath));
      await launchUrl(Uri.file(outputPaths.addressesPath));
      await launchUrl(Uri.file(outputPaths.hoistPatchPath));
    }
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
        store, uid, multiOutlet.desiredSpareCircuits + 1);
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
        store, uid, multiOutlet.desiredSpareCircuits - 1);
  };
}

void _updatePowerMultiSpareCircuitCount(
    Store<AppState> store, String uid, int desiredCount) {
  final existingMultiOutlets = store.state.fixtureState.powerMultiOutlets;

  existingMultiOutlets.update(
      uid, (existing) => existing.copyWith(desiredSpareCircuits: desiredCount));

  store.dispatch(SetPowerMultiOutlets(existingMultiOutlets));
}

int _findNextAvailableSequenceNumber(List<int> sequenceNumbers) {
  if (sequenceNumbers.isEmpty) {
    return 1;
  }

  if (sequenceNumbers.length == 1) {
    return sequenceNumbers.first + 1;
  }

  final sortedSequenceNumbers = sequenceNumbers.sorted((a, b) => a - b);

  for (final (index, seq) in sortedSequenceNumbers.indexed) {
    if (index + 1 < sortedSequenceNumbers.length) {
      final nextSeq = sortedSequenceNumbers[index + 1];

      if (seq + 1 != nextSeq) {
        return seq + 1;
      }
    }
  }

  return sortedSequenceNumbers.last + 1;
}

/// Validates if we are moving a Hoist from one location to another (Currently disallowed).
/// Will notify the user that is is disallowed and return false, otherwise returns true.
bool _validateAndNotifyHoistMove(int oldIndex, int newIndex,
    List<HoistItemBase> hoistItems, BuildContext context) {
  // We currently shouldn't support moving a Hoist from one location into another, this could cause a lot of headaches with having to
  // update Hybrid positions. So therefore we need to make sure we arent moving from one location to another.
  // To do that, we need to gather a list of [LocationSpan]. This is the starting and ending index of each location,
  // with that information we can determine if the hoist that is reordeing, is crossing a location boundary.
  final locationIndexSpans = hoistItems.foldIndexed<List<LocationSpan>>([],
      (index, accum, value) {
    if (value is! HoistLocationViewModel) {
      return accum;
    }

    // Collect the current Span. This will be the last item in the accumulator, or if there are no items, then create a new span
    // starting at this point.
    LocationSpan currentSpan = accum.lastOrNull ??
        LocationSpan(location: value.location, startingIndex: index);

    // If the current Location does not match the current Span, close off that span and start a new one.
    if (value.location.uid != currentSpan.location.uid) {
      // Close the current Span and start a new one.
      currentSpan.endingIndex = index;
      return [
        ...accum,
        LocationSpan(location: value.location, startingIndex: index)
      ];
    } else {
      return [
        ...accum,
        if (accum.isEmpty || accum.last != currentSpan) currentSpan,
      ];
    }
  })
    ..lastOrNull?.endingIndex = hoistItems.isNotEmpty
        ? hoistItems.length
        : null; // Close off the very last Span.

  final currentHoist = (hoistItems[oldIndex] as HoistViewModel).hoist;
  final currentSpan = locationIndexSpans
      .firstWhereOrNull((span) => span.location.uid == currentHoist.locationId);
  final targetSpan = locationIndexSpans
      .firstWhereOrNull((span) => span.containsIndex(newIndex));

  if (currentSpan == null || targetSpan == null) {
    throw ArgumentError(
        'Either currentSpan or targetSpan were null. This is an error');
  }

  if (currentSpan.location.uid != targetSpan.location.uid) {
    showGenericErrorToast(
        context: context,
        title: "You cannot move a hoist from one location to another, yet.");

    return false;
  }

  return true;
}
