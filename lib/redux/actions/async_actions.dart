import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/classes/export_file_paths.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/containers/import_manager_container.dart';
import 'package:sidekick/data_selectors/select_all_outlets.dart';
import 'package:sidekick/data_selectors/select_outlets.dart';
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_addressing_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_lighting_looms_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/helpers/apply_cable_action_modifiers.dart';
import 'package:sidekick/helpers/combine_dmx_into_sneak.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/helpers/determine_default_loom_name.dart';
import 'package:sidekick/helpers/extract_locations_from_outlets.dart';
import 'package:sidekick/helpers/fill_cables_to_satisfy_permanent_loom.dart';
import 'package:sidekick/model_collection/convert_to_map_entry.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/init_persistent_settings_storage.dart';
import 'package:sidekick/persistent_settings/update_persistent_settings.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/screens/file/import_module/import_manager_result.dart';
import 'package:sidekick/screens/looms/add_spare_cables.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/screens/setup_quantities_dialog/setup_quantities_dialog.dart';
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/composition_repair_error_snack_bar.dart';
import 'package:sidekick/snack_bars/export_success_snack_bar.dart';
import 'package:sidekick/snack_bars/file_error_snack_bar.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:sidekick/snack_bars/import_success_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:url_launcher/url_launcher.dart';

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
  ScaffoldMessenger.of(context).showSnackBar(
    genericErrorSnackBar(
      context: context,
      message: 'Unable to match suitable Permanent loom.',
      extendedMessage: error,
    ),
  );
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

ThunkAction<AppState> splitSelectedSneakIntoDmx(BuildContext context) {
  return (Store<AppState> store) async {
    final sneakCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.type == CableType.sneak);

    if (sneakCables.isEmpty) {
      return;
    }

    // Determine if we need to remove any Data Multis. This should only be the case where we are splitting a Feeder Sneak.
    final dataMultisToRemove = sneakCables
        .where((cable) => cable.upstreamId.isEmpty)
        .map((cable) => cable.outletId)
        .toSet();

    final sneakIds = sneakCables.map((cable) => cable.uid).toSet();

    final associatedChildren = store.state.fixtureState.cables.values
        .where((cable) => sneakIds.contains(cable.parentMultiId));

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(associatedChildren
          .map((child) => child.copyWith(parentMultiId: ''))
          .toModelMap())
      ..removeWhere((key, value) => sneakIds.contains(key))));

    if (dataMultisToRemove.isNotEmpty) {
      store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
        ..removeWhere((key, _) => dataMultisToRemove.contains(key))));
    }
  };
}

ThunkAction<AppState> combineSelectedDataCablesIntoSneak(
    BuildContext context) {
  return (Store<AppState> store) async {
    final validCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.type == CableType.dmx)
        .toList();

    final combinationResult = combineDmxIntoSneak(
        cables: validCables,
        outlets: [
          ...store.state.fixtureState.dataMultis.values,
          ...store.state.fixtureState.powerMultiOutlets.values,
          ...store.state.fixtureState.dataPatches.values,
        ].toModelMap(),
        existingLocations: store.state.fixtureState.locations,
        reusableSneaks: validCables
            .map((cable) => cable.parentMultiId)
            .map((sneakId) => store.state.fixtureState.cables[sneakId])
            .nonNulls
            .toList());

    store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
      ..addAll([combinationResult.location].toModelMap())));

    store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
      ..addAll(combinationResult.newDataMultis.toModelMap())));

    final cableIdsToRemove =
        combinationResult.cablesToDelete.map((cable) => cable.uid).toSet();

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll(combinationResult.cables.toModelMap())
          ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
      ),
    );

    store.dispatch(SetSelectedCableIds(
        combinationResult.cables.map((cable) => cable.uid).toSet()));
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

    final associatedLocations = extractLocationsFromOutlets(
        [...dataOutlets, ...powerMultiOutlets],
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
      locations: store.state.fixtureState.locations,
      loom: newLoom,
      outlets: [
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.dataPatches.values
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
      locations: store.state.fixtureState.locations,
      loom: newLoom,
      outlets: [
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.dataPatches.values
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
        ScaffoldMessenger.of(context)
            .showSnackBar(importSuccessSnackBar(context));
      }
    } else {
      store.dispatch(SetImportManagerStep(ImportManagerStep.fileSelect));
    }
  };
}

ThunkAction<AppState> setImportPath(BuildContext context, String importPath) {
  return (Store<AppState> store) async {
    final sourceFile = File(importPath);
    final fileExtension = p.extension(importPath);

    if (await sourceFile.exists() == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: 'File cannot be found.',
          extendedMessage: 'Could not find file at location:\n$importPath'));
      return;
    }

    final extensionRegex = RegExp(r'.xlsx|.xls');

    if (extensionRegex.hasMatch(fileExtension) == false) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
        context: context,
        message: 'Invalid file format. Only excel files are supported.',
      ));
      return;
    }

    late final Uint8List bytes;
    try {
      bytes = await sourceFile.readAsBytes();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message:
              'Unable to read file. Ensure the file is not currently open in Excel',
          error: e,
        ));
      }
      return;
    }

    late final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: 'Unable to decode Excel file.',
          extendedMessage: e.toString(),
          error: e,
        ));
      }

      return;
    }

    store.dispatch(
        SetExcelSheetNames(excel.sheets.keys.toSet(), excel.getDefaultSheet()));
    store.dispatch(SetPatchImportFilePath(importPath));
    store.dispatch(SetImportExcelDocument(excel));
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
      ScaffoldMessenger.of(homeScaffoldKey.currentContext!).showSnackBar(
          compositionRepairSnackBar(context,
              'Unable to auto repair composition. Try combining DMX into Sneak or convert to a custom loom. Provided reason: ${firstRunCompositionResult.error}'));
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

    final selectedCablesWithChildren = [
      ...selectedCables,
      ...sneaks.expand((sneak) => store.state.fixtureState.cables.values
          .where((cable) => cable.parentMultiId == sneak.uid)),
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

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..removeWhere((key, value) => cableIdsToRemove.contains(key))));

    if (dataMultiIdsToRemove.isNotEmpty) {
      store.dispatch(SetDataMultis(store.state.fixtureState.dataMultis.clone()
        ..removeWhere((key, __) => dataMultiIdsToRemove.contains(key))));
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

    final result = await showModalBottomSheet(
        barrierColor: Colors.black.withAlpha(64),
        elevation: 20,
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

    store.dispatch(SetSelectedCableIds({}));
  };
}

ThunkAction<AppState> debugButtonPressed() {
  return (Store<AppState> store) async {
    print("Debug Button Pressed");

    store.dispatch(SetFixtures(store.state.fixtureState.fixtures));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(fileSaveSuccessSnackBar(context));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
            context: context,
            message: 'An error occurred saving the project',
            error: e,
            extendedMessage: e.toString()));
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
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(context,
            'Parent directory could not be found. Have you selected a target directory?'));
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
      dataMultis: store.state.fixtureState.dataMultis,
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

    createLightingLoomsSheet(
      excel: loomsExcel,
      store: store,
    );

    loomsExcel.delete('Sheet1');

    final referenceDataBytes = referenceDataExcel.save();
    final loomsBytes = loomsExcel.save();
    final powerPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_power_patch.xlsx');
    final dataPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_data_patch.xlsx');

    if (referenceDataBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'An error occured writing reference data excel'));
      }

      return;
    }

    if (loomsBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'An error occured writing looms data excel'));
      }

      return;
    }

    final addressingExcel = Excel.createExcel();

    createFixtureAddressingSheet(
      fixtures: store.state.fixtureState.fixtures.values.toList(),
      locations: store.state.fixtureState.locations,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      excel: addressingExcel,
      projectName: store.state.fileState.projectMetadata.projectName,
    );

    final addressingBytes = addressingExcel.save();

    if (addressingBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'An error occured writing the Fixture Addressing sheet'));
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
    ];

    try {
      await Future.wait(fileWrites);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'One or more files failed to write to disk'));

        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(exportSuccessSnackbar(context));
    }

    if (store.state.navstate.openAfterExport == true) {
      await launchUrl(Uri.file(outputPaths.powerPatchPath));
      await launchUrl(Uri.file(outputPaths.dataPatchPath));
      await launchUrl(Uri.file(outputPaths.loomsPath));
      await launchUrl(Uri.file(outputPaths.addressesPath));
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
