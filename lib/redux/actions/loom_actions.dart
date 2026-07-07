import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;

import 'package:sidekick/assert_sneak_child_spares.dart';
import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/data_selectors/select_all_outlets.dart';
import 'package:sidekick/data_selectors/select_outlets.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/helpers/apply_cable_action_modifiers.dart';
import 'package:sidekick/helpers/cable_combiners.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/helpers/determine_default_loom_name.dart';
import 'package:sidekick/helpers/extract_locations_from_outlets.dart';
import 'package:sidekick/helpers/fill_cables_to_satisfy_permanent_loom.dart';
import 'package:sidekick/model_collection/convert_to_map_entry.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/add_spare_cables.dart';
import 'package:sidekick/toasts.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> addCablesToLoomAsExtensions(
  BuildContext context,
  String loomId,
  Set<String> cableIds,
) {
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
          ),
        );
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
              .map(
                (child) => child.copyWith(
                  uid: getUid(),
                  upstreamId: child.uid,
                  parentMultiId: newParentId,
                  loomId: loom.uid,
                ),
              )
              .toList(),
        );
      }
    });

    final extensionCables = CableFamily.flattened(extensionCableFamilies);

    store.dispatch(
      SetCables(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..addAll(extensionCables.toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> changeToSpecificComposition(
  BuildContext context,
  String loomId,
  PermanentCompositionSelection newSelection,
) {
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
        .where(
          (cable) => newSelection.cutSpares ? cable.isSpare == false : true,
        ) // If user wants to obliterate spares, Filter them out.
        .toList();

    final updatedLoom = loom.copyWith(
      type: loom.type.copyWith(
        permanentComposition: newSelection.name,
        length: concreteComposition.validLengths.contains(loom.type.length)
            ? loom.type.length
            : loom.type.length + 5,
      ),
    );

    final updatedChildren = fillCablesToSatisfyPermanentLoom(
      updatedLoom,
      existingChildren,
    );

    // If the user has opted to select a Compostion which will involve anihilating the spares, capture those Ids here to be removed.
    final originalSparesToMaybeRemove = newSelection.cutSpares
        ? store.state.fixtureState.cables.values
              .where(
                (cable) => cable.loomId == loom.uid && cable.isSpare == true,
              )
              .map((cable) => cable.uid)
              .toSet()
        : <String>{};

    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(updatedChildren.toModelMap())
          ..removeWhere((key, _) => originalSparesToMaybeRemove.contains(key)),
        store.state.fixtureState.looms.clone()
          ..addAll([updatedLoom].toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> changeSelectedCablesToDefaultPowerMultiType() {
  return (Store<AppState> store) async {
    final cables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList()
        .where(
          (cable) =>
              cable.type == CableType.socapex ||
              cable.type == CableType.wieland6way,
        );

    if (cables.isEmpty) {
      return;
    }

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()..addAll(
          cables
              .map(
                (cable) => cable.copyWith(
                  type: store.state.fixtureState.defaultPowerMulti,
                ),
              )
              .toModelMap(),
        ),
      ),
    );
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

      store.dispatch(
        SetCablesAndLooms(
          store.state.fixtureState.cables.clone()
            ..addAll(updatedCables.toModelMap()),
          store.state.fixtureState.looms.clone()
            ..addAll([updatedLoom].toModelMap()),
        ),
      );
      return;
    }

    // Existing Loom is a Custom so we (attempting) to toggle it to a Permanent.
    final (updatedCables, updatedLoom, error) = convertToPermanentLoom(
      children,
      loom,
    );

    if (error != null) {
      _showFailedPermanentLoomErrorMessage(context, error);
      return;
    }

    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(updatedCables.toModelMap()),
        store.state.fixtureState.looms.clone()
          ..addAll([updatedLoom].toModelMap()),
      ),
    );
  };
}

void _showFailedPermanentLoomErrorMessage(BuildContext context, String error) {
  showGenericErrorToast(
    context: context,
    title: 'Unable to match suitable Permanent loom',
    extendedMessage: error,
  );
}

(List<CableModel> updatedCables, LoomModel updatedLoom) _convertToCustomLoom(
  List<CableModel> cables,
  LoomModel loom,
) {
  // Super easy to go from Permanent to Custom.
  final updatedLoom = loom.copyWith(
    type: loom.type.copyWith(type: LoomType.custom, permanentComposition: ''),
  );

  // Ensure the Child cables all adopt the original Permanent Looms Length.
  final updatedChildCables = cables
      .map((cable) => cable.copyWith(length: updatedLoom.type.length))
      .toList();

  return (updatedChildCables, updatedLoom);
}

ThunkAction<AppState> reorderLooms(
  BuildContext context,
  int oldIndex,
  int newIndex,
) {
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
  BuildContext context,
  String targetLoomId,
  Set<String> cableIds,
) {
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

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll(updatedCables.toModelMap()),
      ),
    );
  };
}

ThunkAction<AppState> splitSelectedMultis(BuildContext context) {
  return (Store<AppState> store) async {
    final multiCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.isMultiCable);

    if (multiCables.isEmpty) {
      return;
    }

    // Determine if we need to remove any Multi Outlets. This should only be the case when we are removing a Feeder multi.
    final multiIdsToRemove = multiCables
        .where((cable) => cable.upstreamId.isEmpty)
        .map((cable) => cable.outletId)
        .toSet();

    final multiIds = multiCables.map((cable) => cable.uid).toSet();

    final associatedChildren = store.state.fixtureState.cables.values.where(
      (cable) => multiIds.contains(cable.parentMultiId),
    );

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll(
            associatedChildren
                .map((child) => child.copyWith(parentMultiId: ''))
                .toModelMap(),
          )
          ..removeWhere((key, value) => multiIds.contains(key)),
      ),
    );

    if (multiIdsToRemove.isNotEmpty) {
      store.dispatch(
        SetDataMultis(
          store.state.fixtureState.dataMultis.clone()
            ..removeWhere((key, _) => multiIdsToRemove.contains(key)),
        ),
      );

      store.dispatch(
        SetHoistMultis(
          store.state.fixtureState.hoistMultis.clone()
            ..removeWhere((key, _) => multiIdsToRemove.contains(key)),
        ),
      );
    }
  };
}

ThunkAction<AppState> combineSelectedCablesIntoMultis(BuildContext context) {
  return (Store<AppState> store) async {
    final validCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where(
          (cable) =>
              cable.type == CableType.dmx || cable.type == CableType.hoist,
        )
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
          .toList(),
    );

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
          .toList(),
    );

    store.dispatch(
      SetLocations(
        store.state.fixtureState.locations.clone()..addAll(
          [
            ...sneakCombinationResult.locations,
            ...hoistMultiCombinationResult.locations,
          ].toModelMap(),
        ),
      ),
    );

    store.dispatch(
      SetDataMultis(
        store.state.fixtureState.dataMultis.clone()
          ..addAll(sneakCombinationResult.newDataMultis.toModelMap()),
      ),
    );

    store.dispatch(
      SetHoistMultis(
        store.state.fixtureState.hoistMultis.clone()
          ..addAll(hoistMultiCombinationResult.newHoistMultis.toModelMap()),
      ),
    );

    final cableIdsToRemove = [
      ...sneakCombinationResult.cablesToDelete,
      ...hoistMultiCombinationResult.cablesToDelete,
    ].map((cable) => cable.uid).toSet();

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()
          ..addAll(
            [
              ...sneakCombinationResult.cables,
              ...hoistMultiCombinationResult.cables,
            ].toModelMap(),
          )
          ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
      ),
    );

    store.dispatch(
      SetSelectedCableIds(
        sneakCombinationResult.cables.map((cable) => cable.uid).toSet(),
      ),
    );
  };
}

ThunkAction<AppState> createNewLoomFromExistingCables(
  BuildContext context,
  List<String> cableIds,
  int insertIndex,
  Set<CableActionModifier> modifiers,
) {
  return (Store<AppState> store) async {
    final newLoomId = getUid();

    final updatedCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .map((cable) => cable.copyWith(loomId: newLoomId))
        .toList();

    if (updatedCables.isEmpty) {
      return;
    }

    final associatedLocations = extractLocationsFromOutlets(
      updatedCables
          .map((cable) => cable.outletId)
          .map(
            (outletId) => [
              store.state.fixtureState.powerMultiOutlets[outletId],
              store.state.fixtureState.dataMultis[outletId],
              store.state.fixtureState.dataPatches[outletId],
              store.state.fixtureState.hoists[outletId],
              store.state.fixtureState.hoistMultis[outletId],
            ],
          )
          .flattened
          .nonNulls
          .toList(),
      store.state.fixtureState.locations,
    );

    final newLoom = LoomModel(
      uid: newLoomId,
      type: LoomTypeModel(
        length: updatedCables.first.length,
        type: LoomType.custom,
      ),
      name: determineDefaultLoomName(
        associatedPrimaryLocation: associatedLocations.first,
        children: updatedCables,
        existingLooms: store.state.fixtureState.looms,
        existingOutlets: selectAllOutlets(store),
        existingCables: store.state.fixtureState.cables,
      ),
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
      context,
      store,
      actionModifierResult,
    );

    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(actionModifierResult.cables),
        store.state.fixtureState.looms.copyWithInsertedEntry(
          (insertIndex - 1).clamp(0, 99999),
          convertToMapEntry(actionModifierResult.loom),
        ),
      ),
    );

    store.dispatch(
      SetSelectedCableIds(updatedCables.map((cable) => cable.uid).toSet()),
    );
  };
}

ThunkAction<AppState> createNewFeederLoom(
  BuildContext context,
  List<String> outletIds,
  int insertIndex,
  Set<CableActionModifier> modifiers,
) {
  return (Store<AppState> store) async {
    final newLoomId = getUid();

    // Create corresponding Cables for Each outlet.
    final dataOutlets = outletIds
        .map((id) => store.state.fixtureState.dataPatches[id])
        .nonNulls;
    final powerMultiOutlets = outletIds
        .map((id) => store.state.fixtureState.powerMultiOutlets[id])
        .nonNulls;
    final hoistOutlets = outletIds
        .map((id) => store.state.fixtureState.hoists[id])
        .nonNulls;

    final associatedLocations = extractLocationsFromOutlets([
      ...dataOutlets,
      ...powerMultiOutlets,
      ...hoistOutlets,
    ], store.state.fixtureState.locations);

    final targetLength = associatedLocations
        .map(
          (location) => location.color.colors.firstOrNull?.defaultLength ?? 0,
        )
        .sorted((a, b) => a.floor() - b.floor())
        .last;

    final List<CableModel> newCables = [
      ...powerMultiOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: store.state.fixtureState.defaultPowerMulti,
          loomId: newLoomId,
          length: targetLength,
        ),
      ),
      ...dataOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.dmx,
          length: targetLength,
          loomId: newLoomId,
        ),
      ),
      ...hoistOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.hoist,
          length: targetLength,
          loomId: newLoomId,
        ),
      ),
    ];

    final newLoom = LoomModel(
      uid: newLoomId,
      type: LoomTypeModel(length: targetLength, type: LoomType.custom),
      name: determineDefaultLoomName(
        associatedPrimaryLocation: associatedLocations.first,
        children: newCables,
        existingLooms: store.state.fixtureState.looms,
        existingOutlets: selectAllOutlets(store),
        existingCables: store.state.fixtureState.cables,
      ),
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
      context,
      store,
      actionModifierResult,
    );

    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(actionModifierResult.cables),
        store.state.fixtureState.looms.copyWithInsertedEntry(
          (insertIndex - 1).clamp(0, 99999),
          convertToMapEntry(actionModifierResult.loom),
        ),
      ),
    );

    store.dispatch(
      SetSelectedCableIds(newCables.map((cable) => cable.uid).toSet()),
    );
  };
}

void _performPostCableActionModifierDispatches(
  BuildContext context,
  Store<AppState> store,
  CableActionModifierResult actionModifierResult,
) {
  if (actionModifierResult.permanentLoomConversionError != null) {
    _showFailedPermanentLoomErrorMessage(
      context,
      actionModifierResult.permanentLoomConversionError!,
    );
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

ThunkAction<AppState> createNewExtensionLoom(
  BuildContext context,
  List<String> cableIds,
  int index,
  Set<CableActionModifier> modifiers,
) {
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
          ),
        );
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
              .map(
                (child) => child.copyWith(
                  uid: getUid(),
                  parentMultiId: clonedParent.uid,
                  upstreamId: child.uid,
                  loomId: newLoom.uid,
                ),
              )
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
      context,
      store,
      actionModifierResult,
    );

    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..addAll(actionModifierResult.cables),
        store.state.fixtureState.looms.copyWithInsertedEntry(
          (index - 1).clamp(0, 99999),
          convertToMapEntry(actionModifierResult.loom),
        ),
      ),
    );

    store.dispatch(
      SetSelectedCableIds(
        actionModifierResult.cables.values
            .where((cable) => cable.loomId == newLoom.uid)
            .map((cable) => cable.uid)
            .toSet(),
      ),
    );
  };
}

ThunkAction<AppState> changeExistingPowerMultisToDefault(BuildContext context) {
  return (Store<AppState> store) async {
    final targetValue = store.state.fixtureState.defaultPowerMulti;
    final existingValue = targetValue == CableType.socapex
        ? CableType.wieland6way
        : CableType.socapex;

    final updatedCables = store.state.fixtureState.cables.clone()
      ..updateAll(
        (_, existingCable) => existingCable.type == existingValue
            ? existingCable.copyWith(type: targetValue)
            : existingCable,
      );

    String permanentCompositionNameSwitcher(String value) =>
        targetValue == CableType.socapex
        ? value.replaceAll(kWielandSlug, kSocaSlug)
        : value.replaceAll(kSocaSlug, kWielandSlug);

    final keyword = existingValue == CableType.socapex
        ? kSocaSlug
        : kWielandSlug;
    final updatedLooms = store.state.fixtureState.looms.clone()
      ..updateAll(
        (_, existingLoom) =>
            existingLoom.type.permanentComposition.contains(keyword)
            ? existingLoom.copyWith(
                type: existingLoom.type.copyWith(
                  permanentComposition: permanentCompositionNameSwitcher(
                    existingLoom.type.permanentComposition,
                  ),
                ),
              )
            : existingLoom,
      );

    store.dispatch(SetCablesAndLooms(updatedCables, updatedLooms));
  };
}

ThunkAction<AppState> repairLoomComposition(
  LoomModel loom,
  BuildContext context,
) {
  return (Store<AppState> store) async {
    final parentCables = store.state.fixtureState.cables.values
        .where(
          (cable) => cable.loomId == loom.uid && cable.parentMultiId.isEmpty,
        )
        .toList();

    // Attempt a simple repair first.
    final firstRunCompositionResult =
        PermanentLoomComposition.matchSuitablePermanent(parentCables);

    if (firstRunCompositionResult.error == null) {
      store.dispatch(
        SetCablesAndLooms(
          // Cables
          store.state.fixtureState.cables.clone()..addAll(
            _generateSpareCablesToMeetComposition(
              loom,
              parentCables,
              firstRunCompositionResult.composition,
            ).toModelMap(),
          ),
          // Looms
          store.state.fixtureState.looms.clone()..update(
            loom.uid,
            (_) => loom.copyWith(
              type: loom.type.copyWith(
                permanentComposition:
                    firstRunCompositionResult.composition.name,
              ),
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
        extendedMessage: firstRunCompositionResult.error,
      );
    }
  };
}

List<CableModel> _generateSpareCablesToMeetComposition(
  LoomModel existingLoom,
  List<CableModel> existingParentCablesInLoom,
  PermanentLoomComposition targetComposition,
) {
  // Create any Spare cables if we have to in order to reach the desired composition.
  final cablesByType = existingParentCablesInLoom.groupListsBy(
    (cable) => cable.type,
  );
  final neededSocaWays =
      targetComposition.socaWays -
      (cablesByType[CableType.socapex]?.length ?? 0).clamp(0, 100);
  final neededWielandWays =
      targetComposition.wieland6Ways -
      (cablesByType[CableType.wieland6way]?.length ?? 0).clamp(0, 100);
  final neededSneakWays =
      targetComposition.sneakWays -
      (cablesByType[CableType.sneak]?.length ?? 0).clamp(0, 100);
  final neededDmxWays =
      targetComposition.dmxWays -
      (cablesByType[CableType.dmx]?.length ?? 0).clamp(0, 100);

  final existingSpareCablesByType = cablesByType.map(
    (key, value) =>
        MapEntry(key, value.where((cable) => cable.isSpare == true).toList()),
  );

  List<CableModel> generateSpares(int qty, CableType type) =>
      List<CableModel>.generate(
        qty,
        (index) => CableModel(
          uid: getUid(),
          loomId: existingLoom.uid,
          type: type,
          length: existingLoom.type.length,
          isSpare: true,
          spareIndex:
              (index + 1) + (existingSpareCablesByType[type]?.length ?? 0),
        ),
      );

  return [
    ...generateSpares(neededSocaWays, CableType.socapex),
    ...generateSpares(neededWielandWays, CableType.wieland6way),
    ...generateSpares(neededSneakWays, CableType.sneak),
    ...generateSpares(neededDmxWays, CableType.dmx),
  ];
}

ThunkAction<AppState> setSelectedCableIds(Set<String> ids) {
  return (Store<AppState> store) async {
    final cables = ids
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    // If we have selected any Parent Multi cable, select all it's children as well.
    final withChildCables = cables.expand(
      (cable) => cable.isMultiCable
          ? [
              // Parent Multi Cable
              cable,

              // It's Children.
              ...store.state.fixtureState.cables.values.where(
                (child) => child.parentMultiId == cable.uid,
              ),
            ]
          : [cable],
    );

    store.dispatch(
      SetSelectedCableIds(withChildCables.map((cable) => cable.uid).toSet()),
    );
  };
}

ThunkAction<AppState> deleteSelectedCables(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    final sneaks = selectedCables.where(
      (cable) => cable.type == CableType.sneak,
    );

    final hoistMultis = selectedCables.where(
      (cable) => cable.type == CableType.hoistMulti,
    );

    final selectedCablesWithChildren = [
      ...selectedCables,
      ...sneaks.expand(
        (sneak) => store.state.fixtureState.cables.values.where(
          (cable) => cable.parentMultiId == sneak.uid,
        ),
      ),
      ...hoistMultis.expand(
        (multi) => store.state.fixtureState.cables.values.where(
          (cable) => cable.parentMultiId == multi.uid,
        ),
      ),
    ];

    final cableIdsToRemove = selectedCablesWithChildren
        .map((cable) => cable.uid)
        .toSet();

    // Select DataMultiOutlet Ids to remove. We predicate this on if their are no other cables (ie extensions) that are
    // dependenent on that outlet.
    final dataMultiIdsToRemove = sneaks
        .map((sneak) {
          final otherSneakCablesWithSameOutlet = store
              .state
              .fixtureState
              .cables
              .values
              .where(
                (cable) =>
                    cable.outletId == sneak.outletId && cable.uid != sneak.uid,
              );

          return otherSneakCablesWithSameOutlet.isEmpty ? sneak.outletId : null;
        })
        .nonNulls
        .toSet();

    // Select Hoist Multi Outlets Ids to remove. We predicate this on if their are no other cables (ie extensions) that are
    // dependenent on that outlet.
    final hoistMultiIdsToRemove = hoistMultis
        .map((multi) {
          final otherHoistMultisWithSameOutlet = store
              .state
              .fixtureState
              .cables
              .values
              .where(
                (cable) =>
                    cable.outletId == multi.outletId && cable.uid != multi.uid,
              );

          return otherHoistMultisWithSameOutlet.isEmpty ? multi.outletId : null;
        })
        .nonNulls
        .toSet();

    store.dispatch(
      SetCables(
        assertMultiChildSpares(
          store.state.fixtureState.cables.clone()
            ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
        ),
      ),
    );

    if (dataMultiIdsToRemove.isNotEmpty) {
      store.dispatch(
        SetDataMultis(
          store.state.fixtureState.dataMultis.clone()
            ..removeWhere((key, _) => dataMultiIdsToRemove.contains(key)),
        ),
      );
    }

    if (hoistMultiIdsToRemove.isNotEmpty) {
      store.dispatch(
        SetHoistMultis(
          store.state.fixtureState.hoistMultis.clone()
            ..removeWhere((key, _) => hoistMultiIdsToRemove.contains(key)),
        ),
      );
    }
  };
}

ThunkAction<AppState> addSpareCablesToLoom(
  BuildContext context,
  String loomId,
) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final result = await openShadSheet(
      context: context,
      builder: (context) => AddSpareCables(
        defaultPowerMultiType: store.state.fixtureState.defaultPowerMulti,
      ),
    );

    if (result == null) {
      return;
    }

    if (result is AddSpareCablesResult) {
      final values = result.values;

      // Expand the values from the Dialog into a List of CableTypes. This makes it easier to reduce
      // these values later on.
      final expandedTypes = values.expand(
        (value) => List<CableType>.generate(value.qty, (index) => value.type),
      );

      final existingCablesInLoom = store.state.fixtureState.cables.values.where(
        (cable) => cable.loomId == loomId,
      );

      final updatedCables = expandedTypes.fold<List<CableModel>>(
        existingCablesInLoom.toList(),
        (cablesInLoom, type) {
          final existingCablesOfType = cablesInLoom.where(
            (cable) => cable.type == type,
          );

          final existingParentSparesOfType = existingCablesOfType
              .where(
                (cable) => cable.isSpare == true && cable.parentMultiId.isEmpty,
              )
              .toList();

          final newParentCable = CableModel(
            uid: getUid(),
            type: type,
            isSpare: true,
            loomId: loomId,
            length:
                existingParentSparesOfType.firstOrNull?.length ??
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
                  spareIndex: index,
                ),
              ),
          ];
        },
      );

      store.dispatch(
        SetCables(
          store.state.fixtureState.cables.clone()
            ..addAll(updatedCables.toModelMap()),
        ),
      );

      store.dispatch(
        SetSelectedCableIds(
          updatedCables
              .where((cable) => cable.isSpare)
              .map((cable) => cable.uid)
              .toSet(),
        ),
      );
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
  BuildContext context,
  String loomId,
  Set<String> outletIds,
) {
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
      ...outlets.powerOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: store.state.fixtureState.defaultPowerMulti,
          length: loom.type.length,
          loomId: loom.uid,
        ),
      ),
      ...outlets.dataOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.dmx,
          length: loom.type.length,
          loomId: loom.uid,
        ),
      ),
      ...outlets.hoistOutlets.map(
        (outlet) => CableModel(
          uid: getUid(),
          outletId: outlet.uid,
          type: CableType.hoist,
          length: loom.type.length,
          loomId: loom.uid,
        ),
      ),
    ];

    store.dispatch(
      SetCables(
        store.state.fixtureState.cables.clone()..addAll(newCables.toModelMap()),
      ),
    );

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
        .where(
          (cable) =>
              cable.type == CableType.sneak &&
              store.state.fixtureState.cables.values
                  .where(
                    (other) =>
                        other.outletId == cable.outletId &&
                        other.uid != cable.uid,
                  )
                  .isEmpty,
        )
        .map((cable) => cable.outletId)
        .toSet();

    // As Above we need to remove any Hoist Multis.
    final hoistMultiIdsToRemove = allChildCables
        .where(
          (cable) =>
              cable.type == CableType.hoistMulti &&
              store.state.fixtureState.cables.values
                  .where(
                    (other) =>
                        other.outletId == cable.outletId &&
                        other.uid != cable.uid,
                  )
                  .isEmpty,
        )
        .map((cable) => cable.outletId)
        .toSet();

    final cableIdsToRemove = allChildCables.map((cable) => cable.uid).toSet();

    // Delete Cables and Loom
    store.dispatch(
      SetCablesAndLooms(
        store.state.fixtureState.cables.clone()
          ..removeWhere((key, value) => cableIdsToRemove.contains(key)),
        store.state.fixtureState.looms.clone()..remove(loom.uid),
      ),
    );

    // Optionally remove any corresponding DataMulti Outlets.
    if (dataMultiIdsToRemove.isNotEmpty) {
      store.dispatch(
        SetDataMultis(
          store.state.fixtureState.dataMultis.clone()
            ..removeWhere((key, value) => dataMultiIdsToRemove.contains(key)),
        ),
      );
    }

    // Optionally remove any corresponding Hoist Multi outlets.
    if (hoistMultiIdsToRemove.isNotEmpty) {
      store.dispatch(
        SetHoistMultis(
          store.state.fixtureState.hoistMultis.clone()
            ..removeWhere((key, _) => hoistMultiIdsToRemove.contains(key)),
        ),
      );
    }

    store.dispatch(SetSelectedCableIds({}));
  };
}
