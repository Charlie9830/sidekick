import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/data_selectors/select_cable_detached_state.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_label_hint.dart';
import 'package:sidekick/data_selectors/select_cable_location.dart';
import 'package:sidekick/data_selectors/select_child_cables.dart';
import 'package:sidekick/data_selectors/select_dmx_universe.dart';
import 'package:sidekick/item_selection/get_item_selection_index_closure.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

List<LoomViewModel> selectLoomViewModels(
  Store<AppState> store, {
  BuildContext? context,
  bool forExcel = false,
}) {
  // Wrapper Function to wrap multiple similiar calls to Cable VM creation.
  CableViewModel wrapCableVm(
      CableModel cable, int localNumber, int selectionIndex) {
    final associatedLocation = selectCableLocation(cable, store);

    return CableViewModel(
        cable: cable,
        selectionIndex: selectionIndex,
        locationId: associatedLocation?.uid ?? '',
        labelColor: associatedLocation?.color ?? const LabelColorModel.none(),
        isExtension: cable.upstreamId.isNotEmpty,
        universe: selectDmxUniverse(store.state.fixtureState, cable),
        missingUpstreamCable: cable.upstreamId.isNotEmpty
            ? store.state.fixtureState.cables.containsKey(cable.upstreamId) ==
                false
            : false,
        label: selectCableLabel(
          powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
          dataPatches: store.state.fixtureState.dataPatches,
          dataMultis: store.state.fixtureState.dataMultis,
          hoistMultis: store.state.fixtureState.hoistMultis,
          hoistOutlets: store.state.fixtureState.hoists,
          cable: cable,
        ),
        labelHint: selectCableLabelHint(
          powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
          dataPatches: store.state.fixtureState.dataPatches,
          dataMultis: store.state.fixtureState.dataMultis,
          hoistMultis: store.state.fixtureState.hoistMultis,
          hoistOutlets: store.state.fixtureState.hoists,
          cable: cable,
        ),
        isDetached: selectCableDetachedState(
            dataMultis: store.state.fixtureState.dataMultis, cable: cable),
        typeLabel: _getTypeLabel(
          cable.type,
          localNumber,
          isMultiChild: cable.parentMultiId.isNotEmpty,
        ),
        onLengthChanged: (newValue) =>
            store.dispatch(UpdateCableLength(cable.uid, newValue)),
        onNotesChanged: (newValue) =>
            store.dispatch(UpdateCableNote(cable.uid, newValue)));
  }

  final List<LoomModel> orderedLooms =
      store.state.fixtureState.looms.values.toList();

  // Getting a bit stupidly smarty pants here. Create a local closure to track the current 'localNumber' of a cable.
  // The local number pertains to the current count of a type of cable within a loom, for example Soca 1, Soca 2, Soca 3, Sneak 1 etc.
  int Function(CableType type) localNumberCounterClosure() {
    Map<CableType, int> buffer = {
      CableType.socapex: 0,
      CableType.wieland6way: 0,
      CableType.sneak: 0,
      CableType.dmx: 0,
      CableType.hoist: 0,
      CableType.hoistMulti: 0,
    };

    return (CableType type) {
      buffer[type] = buffer[type]! + 1;
      return buffer[type]!;
    };
  }

  final getSelectionIndex = getItemSelectionIndexClosure();

  final loomVms = orderedLooms.mapIndexed(
    (index, loom) {
      final topLevelCables = store.state.fixtureState.cables.values
          .where((cable) =>
              cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
          .toList();

      final getCount = localNumberCounterClosure();

      final loomedCableVms = topLevelCables
          .sorted((a, b) => CableModel.compareByType(a, b))
          .map((cable) {
            return [
              // Top Level Cable
              if (cable.parentMultiId.isEmpty)
                wrapCableVm(cable, getCount(cable.type), getSelectionIndex()),

              // Optional Children of Multi Cables.
              ...selectChildCables(cable, store.state.fixtureState).mapIndexed(
                  (index, child) =>
                      wrapCableVm(child, index + 1, getSelectionIndex()))
            ];
          })
          .flattened
          .toList();

      return LoomViewModel(
          loom: loom,
          loomsOnlyIndex: index,
          containsMotorCables: topLevelCables.any((cable) =>
              cable.type == CableType.hoist ||
              cable.type == CableType.hoistMulti),
          hasVariedLengthChildren:
              topLevelCables.map((cable) => cable.length).toSet().length > 1,
          name: _getLoomName(loom, store),
          addOutletsToLoom: (loomId, outletIds) =>
              store.dispatch(addOutletsToLoom(context!, loomId, outletIds)),
          isValidComposition: loom.type.type == LoomType.permanent
              ? loom.type.checkIsValid(topLevelCables)
              : true,
          children: loomedCableVms,
          onRepairCompositionButtonPressed: () =>
              store.dispatch(repairLoomComposition(loom, context!)),
          onLengthChanged: (newValue) =>
              store.dispatch(UpdateLoomLength(loom.uid, newValue)),
          onDelete: () => store.dispatch(
                deleteLoom(context!, loom.uid),
              ),
          onDropperToggleButtonPressed: () => store.dispatch(
                ToggleCableDropperStateByLoom(
                  loom.uid,
                ),
              ),
          onSwitchType: () => store.dispatch(switchLoomType(
                context!,
                loom.uid,
              )),
          addSpareCablesToLoom: () =>
              store.dispatch(addSpareCablesToLoom(context!, loom.uid)),
          onNameChanged: (newValue) =>
              store.dispatch(UpdateLoomName(loom.uid, newValue)),
          onMoveCablesIntoLoom: (loomId, cableIds) =>
              store.dispatch(moveCablesIntoLoom(context!, loomId, cableIds)),
          onAddCablesIntoLoomAsExtensions: (loomId, cableIds) => store.dispatch(
              addCablesToLoomAsExtensions(context!, loomId, cableIds)),
          permCompEntries: _getPermCompEntries(
              context,
              loom,
              topLevelCables
                  .where((cable) => cable.parentMultiId.isEmpty)
                  .toList()),
          onChangeToSpecificComposition: (newComposition) =>
              store.dispatch(changeToSpecificComposition(context!, loom.uid, newComposition)));
    },
  ).toList();

  return loomVms;
}

List<SelectItemButton<PermanentCompositionSelection>> _getPermCompEntries(
    BuildContext? context, LoomModel loom, List<CableModel> topLevelChildren) {
  SelectItemButton<PermanentCompositionSelection> mapComp(
      PermanentLoomComposition comp) {
    final satisfiedOnAllCables = comp.satisfied(topLevelChildren).satisfied;
    final satisfiedOnActiveCablesOnly = comp
        .satisfied(
            topLevelChildren.where((cable) => cable.isSpare == false).toList())
        .satisfied;
    final cutSpares =
        satisfiedOnAllCables == false && satisfiedOnActiveCablesOnly == true;

    final leading = comp.socaWays > 0
        ? const Icon(Icons.electric_bolt, size: 16)
        : const Icon(Icons.power, size: 16);
    final trailing = cutSpares
        ? const SimpleTooltip(
            message: 'Spares will get deleted',
            child: Icon(Icons.cut, size: 16, color: Colors.pink))
        : null;

    return SelectItemButton<PermanentCompositionSelection>(
      value:
          PermanentCompositionSelection(name: comp.name, cutSpares: cutSpares),
      enabled: satisfiedOnAllCables || satisfiedOnActiveCablesOnly,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(child: Text(comp.name)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  SelectItemButton<PermanentCompositionSelection> buildSubtitle(
          String subtitle) =>
      SelectItemButton<PermanentCompositionSelection>(
        value: PermanentCompositionSelection(name: subtitle, cutSpares: false),
        enabled: false,
        child: Text(subtitle).small,
      );

  return [
    buildSubtitle('Socapex'),
    ...PermanentLoomComposition.validCompositions
        .where((comp) => comp.socaWays > 0)
        .map(mapComp),
    buildSubtitle('6 way'),
    ...PermanentLoomComposition.validCompositions
        .where((comp) => comp.wieland6Ways > 0)
        .map(mapComp)
  ];
}

String _getTypeLabel(CableType type, int localNumber,
    {bool isMultiChild = false}) {
  if (isMultiChild) {
    return switch (type) {
      CableType.dmx => 'Data $localNumber',
      CableType.hoist => 'Line $localNumber',
      _ => throw ArgumentError(
          'Invalid multi child, the argument [isMultiChild] has not been set correctly.'),
    };
  }

  return switch (type) {
    CableType.dmx => 'DMX $localNumber',
    CableType.socapex => 'Soca $localNumber',
    CableType.sneak => 'Sneak $localNumber',
    CableType.wieland6way => '6way $localNumber',
    CableType.hoist => 'Motor $localNumber',
    CableType.hoistMulti => 'Motor Multi $localNumber',
    CableType.unknown => "Unknown",
  };
}

String _getLoomName(LoomModel loom, Store<AppState> store) {
  return loom.name;
}
