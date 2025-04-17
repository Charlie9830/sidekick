import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/classes/export_file_paths.dart';
import 'package:sidekick/classes/universe_span.dart';
import 'package:sidekick/containers/import_manager_container.dart';
import 'package:sidekick/data_selectors/select_outlets.dart';
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_custom_looms_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_permanent_looms_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/excel/new/read_raw_patch_data.dart';
import 'package:sidekick/excel/read_fixture_type_database.dart';
import 'package:sidekick/excel/read_fixtures_patch_data.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/helpers/apply_cable_action_modifiers.dart';
import 'package:sidekick/helpers/combine_dmx_into_sneak.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/import_merging/merge_fixtures.dart';
import 'package:sidekick/model_collection/convert_to_map_entry.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/init_persistent_settings_storage.dart';
import 'package:sidekick/persistent_settings/updatePersistentSettings.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/screens/looms/add_spare_cables.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/composition_repair_error_snack_bar.dart';
import 'package:sidekick/snack_bars/export_success_snack_bar.dart';
import 'package:sidekick/snack_bars/file_error_snack_bar.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:url_launcher/url_launcher.dart';

ThunkAction<AppState> switchLoomTypeV2(BuildContext context, String loomId) {
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

ThunkAction<AppState> splitSelectedSneakIntoDmxV2(BuildContext context) {
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
      store.dispatch(SetDataMultis(
          store.state.fixtureState.dataMultis.clone()
            ..removeWhere((key, _) => dataMultisToRemove.contains(key))));
    }
  };
}

ThunkAction<AppState> combineSelectedDataCablesIntoSneakV2(
    BuildContext context) {
  return (Store<AppState> store) async {
    final validCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.type == CableType.dmx)
        .toList();

    final combinationResult = combineDmxIntoSneak(
      validCables,
      [
        ...store.state.fixtureState.dataMultis.values,
        ...store.state.fixtureState.powerMultiOutlets.values,
        ...store.state.fixtureState.dataPatches.values,
      ].toModelMap(),
      store.state.fixtureState.locations,
    );

    store.dispatch(SetLocations(store.state.fixtureState.locations.clone()
      ..addAll([combinationResult.location].toModelMap())));

    store.dispatch(SetDataMultis(
        store.state.fixtureState.dataMultis.clone()
          ..addAll(combinationResult.newDataMultis.toModelMap())));

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll(
            combinationResult.cables.toModelMap(),
          ),
      ),
    );

    store.dispatch(SetSelectedCableIds(
        combinationResult.cables.map((cable) => cable.uid).toSet()));
  };
}

ThunkAction<AppState> createNewFeederLoomV2(
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

    final List<CableModel> newCables = [
      ...powerMultiOutlets.map((outlet) => CableModel(
            uid: getUid(),
            outletId: outlet.uid,
            type: store.state.fixtureState.defaultPowerMulti,
            loomId: newLoomId,
          )),
      ...dataOutlets.map((outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.dmx,
          loomId: newLoomId)),
    ];

    final newLoom = LoomModel(
      uid: newLoomId,
      loomClass: LoomClass.feeder,
      type: LoomTypeModel(length: 0, type: LoomType.custom),
      name: 'Unnamed Feeder',
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

ThunkAction<AppState> createNewExtensionLoomV2(BuildContext context,
    List<String> cableIds, int index, Set<CableActionModifier> modifiers) {
  return (Store<AppState> store) async {
    final cables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    final newLoom = LoomModel(
      uid: getUid(),
      loomClass: LoomClass.extension,
      type: LoomTypeModel(length: 0, type: LoomType.custom),
    );

    final cableFamilies = CableFamily.createFamilies(cables);

    final clonedFamilies = cableFamilies.map((family) {
      if (family.children.isEmpty) {
        // Standard Cable
        return family.copyWith(
            parent: family.parent.copyWith(
          uid: getUid(),
          upstreamId: family.parent.uid,
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

ThunkAction<AppState> openImportManager(BuildContext context) {
  return (Store<AppState> store) async {
    store.dispatch(readInitialRawPatchData());

    await showDialog(
        context: context,
        builder: (innerContext) => const ImportManagerContainer());
  };
}

ThunkAction<AppState> readInitialRawPatchData() {
  return (Store<AppState> store) async {
    final sheet = store.state.importState.document
        .sheets[store.state.fileState.importSettings.patchDataSourceSheetName]!;

    final rawData = readRawPatchData(sheet, kDataOffset).toList();
    store.dispatch(SetRawPatchData(rawData));
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

    if (firstRunCompositionResult.error != null) {
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

ThunkAction<AppState> removeSelectedCablesFromLoom(BuildContext context) {
  return (Store<AppState> store) async {
    final cables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (cables.isEmpty) {
      return;
    }

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..addAll(
          cables.map((cable) => cable.copyWith(loomId: '')).toModelMap())));
  };
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

    final cablesEligibleForDelete = selectedCables
        .where((cable) => cable.isSpare || cable.upstreamId.isNotEmpty);

    final withSneakChildren =
        cablesEligibleForDelete.expand((cable) => cable.type == CableType.sneak
            ? [
                cable,
                ...store.state.fixtureState.cables.values
                    .where((child) => child.parentMultiId == cable.uid)
              ]
            : [cable]);

    final idsToRemove = withSneakChildren.map((cable) => cable.uid).toSet();

    store.dispatch(SetCables(store.state.fixtureState.cables.clone()
      ..removeWhere((key, value) => idsToRemove.contains(key))));
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
        context: context, builder: (context) => const AddSpareCables());

    if (result == null) {
      return;
    }

    if (result is AddSpareCablesResult) {
      final qty = result.qty;
      final type = result.type;

      final existingCablesOfType = store.state.fixtureState.cables.values
          .where((cable) => cable.loomId == loomId && cable.type == type)
          .toList();
      final existingSpareCablesOfType =
          existingCablesOfType.where((cable) => cable.isSpare == true).toList();

      final newSpareCables = List<CableModel>.generate(qty, (index) {
        return CableModel(
          uid: getUid(),
          type: type,
          isSpare: true,
          length: existingSpareCablesOfType.isNotEmpty
              ? existingSpareCablesOfType.first.length
              : existingCablesOfType.isNotEmpty
                  ? existingCablesOfType.first.length
                  : 0,
          loomId: loomId,
          spareIndex: existingSpareCablesOfType.length + index + 1,
        );
      });

      store.dispatch(SetCables(store.state.fixtureState.cables.clone()
        ..addAll(newSpareCables.toModelMap())));
    }
  };
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

ThunkAction<AppState> deleteLoomV2(BuildContext context, String uid) {
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

    // If we are deleting any Sneaks, we will also need to delete their corresponding DataMutliOutlet.
    final dataMultiIdsToRemove = allChildCables
        .where((cable) => cable.type == CableType.sneak)
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
      store.dispatch(SetDataMultis(
          store.state.fixtureState.dataMultis.clone()
            ..removeWhere((key, value) => dataMultiIdsToRemove.contains(key))));
    }

    store.dispatch(SetSelectedCableIds({}));
  };
}

ThunkAction<AppState> debugButtonPressed() {
  return (Store<AppState> store) async {
    final oldProjectFile = await deserializeProjectFile(
        p.join(p.current, 'test_data', 'difference.phase'));

    final originalCables = oldProjectFile.cables.toSet();
    final originalLooms = oldProjectFile.looms.toSet();

    final currentCables = store.state.fixtureState.cables.values.toSet();
    final currentLooms = store.state.fixtureState.looms.values.toSet();

    store.dispatch(SetDiffingUnions(cables: {
      ...originalCables.map((cable) => UnionProxy(ProxySource.original, cable)),
      ...currentCables.map((cable) => UnionProxy(ProxySource.current, cable)),
    }, looms: {
      ...originalLooms.map((loom) => UnionProxy(ProxySource.original, loom)),
      ...currentLooms.map((loom) => UnionProxy(ProxySource.current, loom)),
    }));

    store.dispatch(SetDiffingOriginalSource(
      oldProjectFile.toFixtureState(),
    ));
  };
}

ThunkAction<AppState> initializeApp(BuildContext context) {
  return (Store<AppState> store) async {
    // Fetch Persistent Settings.
    await initPersistentSettingsStorage();
    final persistentSettings = await fetchPersistentSettings();

    // Set the Fixture Database Path value, and load the Fixture Database if we can.
    if (persistentSettings.fixtureTypeDatabasePath.isNotEmpty) {
      final fixtureTypeDatabaseResult = await readFixtureTypeDatabase(
          persistentSettings.fixtureTypeDatabasePath);
      if (fixtureTypeDatabaseResult.errorMessage == null) {
        store.dispatch(SetFixtureTypeDatabasePath(
            persistentSettings.fixtureTypeDatabasePath));
        store.dispatch(SetIsFixtureTypeDatabasePathValid(true));
        store.dispatch(SetFixtureTypes(fixtureTypeDatabaseResult.fixtureTypes));
      }
    }
  };
}

ThunkAction<AppState> selectFixtureTypeDatabaseFile(
    BuildContext context, String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureTypeDatabasePath(path));

    if (await File(path).exists() == false) {
      store.dispatch(SetIsFixtureTypeDatabasePathValid(false));

      if (homeScaffoldKey.currentContext?.mounted == true) {
        ScaffoldMessenger.of(homeScaffoldKey.currentContext!).showSnackBar(
            fileErrorSnackBar(homeScaffoldKey.currentContext!,
                'Unable to find Fixture Type Database File.'));
      }
      return;
    }

    final result = await readFixtureTypeDatabase(path);

    if (result.errorMessage != null) {
      store.dispatch(SetIsFixtureTypeDatabasePathValid(false));

      if (context.mounted) {
        await showGenericDialog(
            context: context,
            title: 'Error',
            message: result.errorMessage!,
            affirmativeText: "Okay");
      }
      return;
    }

    store.dispatch(SetIsFixtureTypeDatabasePathValid(true));
    store.dispatch(SetFixtureTypes(result.fixtureTypes));

    await updatePersistentSettings(
        (existing) => existing.copyWith(fixtureTypeDatabasePath: path));
  };
}

ThunkAction<AppState> startNewProject(BuildContext context, bool saveCurrent) {
  return (Store<AppState> store) async {
    if (saveCurrent) {
      store.dispatch(saveProjectFile(context, SaveType.save));
    }

    store.dispatch(NewProject());
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
  };
}

ThunkAction<AppState> importPatchFile(BuildContext context) {
  return (Store<AppState> store) async {
    final filePath = store.state.fileState.fixturePatchImportPath;
    final settings = store.state.fileState.importSettings;

    if (settings.mergeWithExisting == false &&
        (store.state.fixtureState.fixtures.isNotEmpty ||
            store.state.fixtureState.locations.isNotEmpty)) {
      final dialogResult = await showGenericDialog(
          context: context,
          title: "Import file",
          message: 'If you continue any unsaved changes will be lost',
          affirmativeText: 'Continue',
          declineText: 'Go back');

      if (dialogResult == null || dialogResult == false) {
        return;
      }
    }

    final fixturesPatchDataResult = await readFixturesPatchData(
      path: filePath,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      patchSheetName: settings.patchDataSourceSheetName,
    );

    if (fixturesPatchDataResult.errorMessage != null) {
      if (context.mounted == true) {
        await showGenericDialog(
            // ignore: use_build_context_synchronously
            context: context,
            title: 'Patch Data Import Error',
            message: fixturesPatchDataResult.errorMessage!,
            affirmativeText: 'Okay');
      }

      return;
    }

    if (settings.mergeWithExisting == true) {
      store.dispatch(
        SetFixtures(
          mergeFixtures(
            existing: store.state.fixtureState.fixtures,
            incoming: fixturesPatchDataResult.fixtures,
            settings: settings,
          ),
        ),
      );
    } else {
      store.dispatch(ResetFixtureState());
      store.dispatch(SetFixtures(fixturesPatchDataResult.fixtures));
      store.dispatch(SetLocations(fixturesPatchDataResult.locations));
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

ThunkAction<AppState> commitDataPatch() {
  return (Store<AppState> store) async {
    final dataPatchesByFixtureId = Map<String, DataPatchModel>.fromEntries(store
        .state.fixtureState.dataPatches.values
        .map((patch) => patch.fixtureIds.map((id) => MapEntry(id, patch)))
        .flattened);

    final updatedFixtures =
        store.state.fixtureState.fixtures.map((uid, fixture) {
      final associatedDataPatch = dataPatchesByFixtureId[uid];

      if (associatedDataPatch == null) {
        return MapEntry(uid, fixture);
      }

      // // TODO: Disabled until refactoring to Cable based Sneak children is complete.
      // final associatedMultiPatch =
      //     store.state.fixtureState.dataMultis[associatedDataPatch.multiId];

      return MapEntry(
          uid,
          fixture.copyWith(
            // dataMulti: associatedMultiPatch?.name ?? '',
            dataPatch: associatedDataPatch.name,
          ));
    });

    store.dispatch(SetFixtures(updatedFixtures));
  };
}

ThunkAction<AppState> generateDataPatch() {
  return (Store<AppState> store) async {
    final fixturesByLocationId = store.state.fixtureState.fixtures.values
        .groupListsBy((fixture) => fixture.locationId);

    final spansByLocationId = fixturesByLocationId.map(
      (locationId, fixtures) => MapEntry(
        locationId,
        store.state.fixtureState.honorDataSpans
            ? UniverseSpan.createSpans(fixtures)
            : fixtures
                .groupListsBy((fix) => fix.dmxAddress.universe)
                .entries
                .map((entry) => UniverseSpan(
                      fixtureIds:
                          entry.value.map((fixture) => fixture.uid).toList(),
                      startsAt: entry.value.first,
                      universe: entry.key,
                      endsAt: entry.value.last,
                    )),
      ),
    );

    final List<DataPatchModel> patches = [];

    for (final entry in spansByLocationId.entries) {
      final locationId = entry.key;
      final spans = entry.value;

      final patchesInLocation = store.state.fixtureState.dataPatches.values
          .where((patch) => patch.locationId == locationId);

      final Queue<DataPatchModel> existingPatches =
          Queue<DataPatchModel>.from(patchesInLocation);

      final location = store.state.fixtureState.locations[locationId]!;

      for (final (index, span) in spans.indexed) {
        final basePatch = existingPatches.isNotEmpty
            ? existingPatches.removeFirst()
            : DataPatchModel(
                uid: getUid(),
                locationId: locationId,
              );

        patches.add(basePatch.copyWith(
          name: location.getPrefixedDataPatch(index + 1),
          number: index + 1,
          universe: span.universe,
          startsAtFixtureId: span.startsAt.fid,
          endsAtFixtureId: span.endsAt?.fid ?? 0,
          fixtureIds: span.fixtureIds,
          isSpare: false,
        ));
      }
    }

    store.dispatch(SetDataPatches(Map<String, DataPatchModel>.fromEntries(
        patches.map((patch) => MapEntry(patch.uid, patch)))));
  };
}

ThunkAction<AppState> commitPowerPatch(BuildContext context) {
  return (Store<AppState> store) async {
    // Map FixtureIds to their associated Power Outlet
    final fixtureLookupMap = Map<String, PowerOutletModel>.fromEntries(
        store.state.fixtureState.outlets
            .map((outlet) => outlet.fixtureIds.map(
                  (id) => MapEntry(id, outlet),
                ))
            .flattened);

    final existingFixtures = store.state.fixtureState.fixtures.clone();

    existingFixtures.updateAll((uid, fixture) {
      final outlet = fixtureLookupMap[uid]!;
      final multiOutlet =
          store.state.fixtureState.powerMultiOutlets[outlet.multiOutletId]!;

      return fixture.copyWith(
        powerMultiId: multiOutlet.uid,
        powerPatch: outlet.multiPatch,
      );
    });

    store.dispatch(SetFixtures(existingFixtures));
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
      outlets: store.state.fixtureState.outlets,
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
      outlets: store.state.fixtureState.outlets,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
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

    createPermanentLoomsSheet(
      excel: loomsExcel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
    );

    createCustomLoomsSheet(
      excel: loomsExcel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
      dataMultis: store.state.fixtureState.dataMultis,
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

    final fileWrites = [
      File(outputPaths.referenceDataPath).writeAsBytes(referenceDataBytes),
      File(outputPaths.loomsPath).writeAsBytes(loomsBytes),
      File(outputPaths.powerPatchPath)
          .writeAsBytes(powerPatchTemplateBytes.buffer.asUint8List()),
      File(outputPaths.dataPatchPath)
          .writeAsBytes(dataPatchTemplateBytes.buffer.asUint8List())
    ];

    try {
      final writeResults = await Future.wait(fileWrites);
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
    }
  };
}

ThunkAction<AppState> generatePatch(BuildContext context) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();

    try {
      final unbalancedMultiOutlets = balancer.assignToOutlets(
        fixtures: fixtures
            .map((fixture) => BalancerFixtureModel.fromFixture(
                fixture: fixture,
                type: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
            .toList(),
        multiOutlets:
            store.state.fixtureState.powerMultiOutlets.values.toList(),
        maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
      );

      final balancedMultiOutlets = _balanceOutlets(
        unbalancedMultiOutlets: unbalancedMultiOutlets,
        balancer: balancer,
        balanceTolerance: store.state.fixtureState.balanceTolerance,
      );

      _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: 'A balancing error occurred',
          extendedMessage: e.toString()));
      rethrow;
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

Map<PowerMultiOutletModel, List<PowerOutletModel>> _balanceOutlets({
  required Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>
      unbalancedMultiOutlets,
  required NaiveBalancer balancer,
  required double balanceTolerance,
}) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  return unbalancedMultiOutlets.map((multiOutlet, outlets) {
    final result = balancer.balanceOutlets(
      outlets,
      balanceTolerance: balanceTolerance,
      initialLoad: currentLoad,
    );

    currentLoad = result.load;

    return MapEntry(
        multiOutlet,
        result.outlets
            .map((balancerOutlet) => PowerOutletModel(
                phase: balancerOutlet.phase,
                multiOutletId: multiOutlet.uid,
                multiPatch: balancerOutlet.multiPatch,
                locationId: balancerOutlet.locationId,
                fixtureIds: balancerOutlet.child.fixtures
                    .map((fixture) => fixture.uid)
                    .toList(),
                load: balancerOutlet.child.amps))
            .toList());
  });
}

void _updatePowerMultisAndOutlets(Store<AppState> store,
    Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets) {
  final balancedAndDefaultNamedOutlets =
      _applyDefaultMultiOutletNames(balancedMultiOutlets, store);

  // Power Outlets
  store.dispatch(SetPowerOutlets(
      balancedAndDefaultNamedOutlets.values.flattened.toList()));

  // Power Multis.
  store.dispatch(
    SetPowerMultiOutlets(
      Map<String, PowerMultiOutletModel>.from(
          balancedAndDefaultNamedOutlets.keys.toModelMap()),
    ),
  );
}

/// Looks up the default Multi Outlet names for outlets that have not been assigned a name.
Map<PowerMultiOutletModel, List<PowerOutletModel>>
    _applyDefaultMultiOutletNames(
        Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets,
        Store<AppState> store) {
  return Map<PowerMultiOutletModel, List<PowerOutletModel>>.fromEntries(
      balancedMultiOutlets.entries.map((entry) {
    final outlet = entry.key;

    final location = store.state.fixtureState.locations[outlet.locationId];

    if (location == null) {
      return entry;
    }

    final multisInLocation = balancedMultiOutlets.keys
        .where((multi) => multi.locationId == location.uid)
        .toList();

    final outletName = location.getPrefixedPowerMulti(
        multisInLocation.length > 1 ? outlet.number : null);

    return MapEntry(
      outlet.copyWith(name: outletName),
      entry.value,
    );
  }));
}

void _updatePowerMultiSpareCircuitCount(
    Store<AppState> store, String uid, int desiredCount) {
  final existingMultiOutlets = store.state.fixtureState.powerMultiOutlets;

  existingMultiOutlets.update(
      uid, (existing) => existing.copyWith(desiredSpareCircuits: desiredCount));

  final balancer = NaiveBalancer();

  final unbalancedMultiOutlets = balancer.assignToOutlets(
    fixtures: store.state.fixtureState.fixtures.values
        .map((fixture) => BalancerFixtureModel.fromFixture(
            fixture: fixture,
            type: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
        .toList(),
    multiOutlets: existingMultiOutlets.values.toList(),
    maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
  );

  final balancedMultiOutlets = _balanceOutlets(
    unbalancedMultiOutlets: unbalancedMultiOutlets,
    balancer: balancer,
    balanceTolerance: store.state.fixtureState.balanceTolerance,
  );

  _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
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
