import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/drag_overlay_region/drag_overlay_region.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/modifier_key_provider.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/modify_existing_loom_drop_targets.dart';
import 'package:sidekick/screens/looms/loom_header.dart';
import 'package:sidekick/screens/looms/loom_item_divider.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/screens/looms/looms_toolbar_contents.dart';
import 'package:sidekick/screens/looms/no_looms_hover_fallback.dart';
import 'package:sidekick/screens/looms/outlet_list_tile.dart';
import 'package:sidekick/screens/looms/quantities_drawer.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class Looms extends StatefulWidget {
  final LoomsViewModel vm;

  const Looms({
    super.key,
    required this.vm,
  });

  @override
  State<Looms> createState() => _LoomsState();
}

class _LoomsState extends State<Looms> {
  @override
  Widget build(BuildContext context) {
    return ModifierKeyProvider(
      child: DragProxyController(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar
            Toolbar(
                child: LoomsToolbarContents(
              onDeleteSelectedCables: widget.vm.onDeleteSelectedCables,
              onCombineIntoMultiButtonPressed:
                  widget.vm.onCombineSelectedDataCablesIntoSneak,
              onSplitMultiButtonPressed: widget.vm.onSplitSneakIntoDmxPressed,
              defaultPowerMultiType: widget.vm.defaultPowerMultiType,
              onDefaultPowerMultiTypeChanged:
                  widget.vm.onDefaultPowerMultiTypeChanged,
              onChangePowerMultiTypeOfSelectedCables:
                  widget.vm.onChangePowerMultiTypeOfSelectedCables,
              availabilityDrawOpen: widget.vm.availabilityDrawOpen,
              onShowAvailabilityDrawPressed:
                  widget.vm.onShowAvailabilityDrawPressed,
            )),

            // Body
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 360,
                    child: Card(
                        child: ItemSelectionContainer<String>(
                      itemIndicies: Map<String, int>.fromEntries(
                          widget.vm.outlets.mapIndexed(
                              (index, outlet) => MapEntry(outlet.uid, index))),
                      selectedItems: widget.vm.selectedLoomOutlets,
                      onSelectionUpdated:
                          widget.vm.onSelectedLoomOutletsChanged,
                      mode: SelectionMode.multi,
                      child: ListView.builder(
                          key: loomOutletsPageStorageKey,
                          itemCount: widget.vm.outlets.length,
                          itemBuilder: (context, index) {
                            final outletVm = widget.vm.outlets[index];

                            if (outletVm is OutletDividerViewModel) {
                              return _buildOutletDivider(outletVm);
                            }

                            final listTile = OutletListTile(
                                isSelected: widget.vm.selectedLoomOutlets
                                    .contains(outletVm.uid),
                                key: Key(outletVm.uid),
                                vm: outletVm);

                            return LongPressDraggableProxy<DragData>(
                              maxSimultaneousDrags:
                                  outletVm.assigned ? 0 : null,
                              data: OutletDragData(outletVms: {
                                outletVm,
                                ...widget.vm.selectedOutletVms,
                              }),
                              onDragStarted: _handleOutletDragStart,
                              onDragCompleted: _handleOutletDragEnd,
                              onDraggableCanceled: _handleOutletDragCancelled,
                              feedback: Opacity(
                                opacity: 0.5,
                                child: Material(
                                  child: SizedBox(
                                      width: 360, height: 56, child: listTile),
                                ),
                              ),
                              child: ItemSelectionListener(
                                value: outletVm.uid,
                                enabled: !outletVm.assigned,
                                child: listTile,
                              ),
                            );
                          }),
                    )),
                  ),
                  Expanded(
                      child: ItemSelectionContainer<String>(
                    selectedItems: widget.vm.selectedCableIds,
                    onSelectionUpdated: _handleCableSelectionUpdate,
                    itemIndicies: _buildCableIndices(),
                    child: widget.vm.loomVms.isNotEmpty
                        ? ReorderableListView.builder(
                            key: loomsPageStorageKey,
                            buildDefaultDragHandles: false,
                            footer: const SizedBox(height: 56),
                            // Use the proxy Decorator to return a simplified version of a Loom Row Item.
                            proxyDecorator: _buildProxyLoomItem,
                            onReorder: widget.vm.onLoomReorder,
                            itemCount: widget.vm.loomVms.length,
                            itemBuilder: (BuildContext context, int index) {
                              return _buildRow(
                                loomVm: widget.vm.loomVms[index],
                                index: index,
                                isLastRow:
                                    index == widget.vm.loomVms.length - 1,
                              );
                            })
                        : NoLoomsHoverFallback(
                            onCreateNewLoom: (outletVms, modifier) =>
                                _handleCreateNewFeederLoom(outletVms, 0,
                                    modifier), // No Looms exist already so we can insert this at index 0.
                          ),
                  )),

                  // Availbility Drawer
                  if (widget.vm.availabilityDrawOpen)
                    QuantatiesDrawer(
                        itemVms: widget.vm.stockVms,
                        onSetupButtonPressed:
                            widget.vm.onSetupQuantiesDrawerButtonPressed)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Builds a simplified Loom Row Item intended to stand in for a loom being drag reordered.
  Widget _buildProxyLoomItem(_, index, animation) {
    return Material(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            LoomHeader(
                loomVm: widget.vm.loomVms[index],
                reorderableListViewIndex: index),
            ...widget.vm.loomVms[index].children.map((cableVm) => CableRowItem(
                  cable: cableVm.cable,
                  labelColor: cableVm.labelColor,
                  label: cableVm.label,
                  typeLabel: cableVm.typeLabel,
                  onNotesChanged: cableVm.onNotesChanged,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletDivider(OutletDividerViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(viewModel.title,
          key: Key(viewModel.uid),
          style: Theme.of(context).textTheme.labelMedium),
    );
  }

  void _handleCableSelectionUpdate(UpdateType type, Set<String> ids) {
    final selectedIds = switch (type) {
      UpdateType.addIfAbsentElseRemove => widget.vm.selectedCableIds.toSet()
        ..addAllIfAbsentElseRemove(ids.cast<String>()),
      UpdateType.overwrite => ids.cast<String>(),
    };

    widget.vm.onSelectCables(selectedIds);
  }

  Map<String, int> _buildCableIndices() {
    return Map<String, int>.fromEntries(widget.vm.loomVms
        .whereType<LoomViewModel>()
        .map((loomVm) => loomVm.children)
        .flattened
        .map((cableVm) => cableVm.cable.uid)
        .mapIndexed((index, id) => MapEntry(id, index)));
  }

  Widget _buildRow({
    required LoomViewModel loomVm,
    required int index,
    required bool isLastRow,
  }) {
    // Helper Function to wrap multiple Divider build Calls.
    buildDivider({
      required int dividerIndex,
      bool expand = false,
    }) =>
        LoomItemDivider(
          expand: expand,
          onDropAsFeeder: (outletVms, modifier) =>
              _handleCreateNewFeederLoom(outletVms, dividerIndex, modifier),
          onDropAsExtension: (cableIds, modifier) =>
              _handleCreateNewExtensionLoom(cableIds, dividerIndex, modifier),
          onDropAsMoveCablesToNewLoom: (cableIds, modifier) =>
              _handleCreateNewLoomFromExistingCables(
                  cableIds, dividerIndex, modifier),
        );

    return Padding(
      key: Key(loomVm.loom.uid),
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upper Divider
          if (index == 0) buildDivider(dividerIndex: index),

          // Loom Item.
          DragOverlayRegion(
            key: Key(loomVm.loom.uid),
            childWhenDraggingOver: ModifyExistingLoomDropTargets(
              onOutletsAdded: (outletVms) => loomVm.addOutletsToLoom(
                  loomVm.loom.uid, outletVms.map((item) => item.uid).toSet()),
              onCablesMoved: (ids) =>
                  loomVm.onMoveCablesIntoLoom(loomVm.loom.uid, ids),
              onCablesAdded: (ids) =>
                  loomVm.onAddCablesIntoLoomAsExtensions(loomVm.loom.uid, ids),
            ),
            child: LoomRowItem(
                loomVm: loomVm,
                reorderableListViewIndex: index,
                children: loomVm.children.mapIndexed((index, cableVm) {
                  final cableWidget = buildCableRowItem(
                      vm: cableVm,
                      index: index,
                      selectedCableIds: widget.vm.selectedCableIds,
                      rowVms: widget.vm.loomVms,
                      parentLoomType: loomVm.loom.type.type,
                      missingUpstreamCable: cableVm.missingUpstreamCable);
                  return LongPressDraggableProxy<CableDragData>(
                    data: CableDragData(
                      cableIds: widget.vm.selectedCableIds,
                    ),
                    feedback: Material(
                        child: SizedBox(width: 700, child: cableWidget)),
                    child:
                        _wrapSelectionListener(vm: cableVm, child: cableWidget),
                  );
                }).toList()),
          ),

          // Lower Divider
          buildDivider(dividerIndex: index + 2, expand: isLastRow),
        ],
      ),
    );
  }

  void _handleCreateNewFeederLoom(List<OutletViewModel> droppedVms,
      int dividerIndex, Set<CableActionModifier> modifiers) {
    widget.vm.onCreateNewFeederLoom(
        droppedVms.map((item) => item.uid).toList(), dividerIndex, modifiers);
  }

  void _handleCreateNewLoomFromExistingCables(List<String> cableIds,
      int dividerIndex, Set<CableActionModifier> modifiers) {
    widget.vm
        .onCreateNewLoomFromExistingCables(cableIds, dividerIndex, modifiers);
  }

  void _handleCreateNewExtensionLoom(List<String> cableIds, int dividerIndex,
      Set<CableActionModifier> modifiers) {
    widget.vm.onCreateNewExtensionLoom(cableIds, dividerIndex, modifiers);
  }

  Widget _wrapSelectionListener(
      {required CableViewModel vm, required Widget child, Key? key}) {
    return ItemSelectionListener<String>(
      key: key,
      value: vm.cable.uid,
      child: child,
    );
  }

  void _handleOutletDragStart() {
    widget.vm.onLoomsDraggingStateChanged(LoomsDraggingState.outletDragging);
  }

  void _handleOutletDragEnd() {
    widget.vm.onLoomsDraggingStateChanged(LoomsDraggingState.idle);
  }

  void _handleOutletDragCancelled(Velocity velocity, Offset offset) {
    _handleOutletDragEnd();
  }
}
