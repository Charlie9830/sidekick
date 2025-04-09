import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/drag_overlay_region/drag_overlay_region.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/modify_existing_loom_drop_targets.dart';
import 'package:sidekick/screens/looms/loom_item_divider.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/screens/looms/looms_toolbar_contents.dart';
import 'package:sidekick/screens/looms/no_looms_hover_fallback.dart';
import 'package:sidekick/screens/looms/outlet_list_tile.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class LoomsV2 extends StatefulWidget {
  final LoomsV2ViewModel vm;

  const LoomsV2({
    super.key,
    required this.vm,
  });

  @override
  State<LoomsV2> createState() => _LoomsV2State();
}

class _LoomsV2State extends State<LoomsV2> {
  final FocusNode _outletsFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return DragProxyController(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Toolbar(
              child: LoomsToolbarContents(
                  onCombineIntoSneakPressed:
                      widget.vm.onCombineSelectedDataCablesIntoSneak,
                  onSplitSneakIntoDmxPressed: widget.vm.onSplitSneakIntoDmxPressed,)),

          // Body
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 360,
                  child: Card(
                      child: ItemSelectionContainer<String>(
                    focusNode: _outletsFocusNode,
                    itemIndicies: Map<String, int>.fromEntries(widget.vm.outlets
                        .mapIndexed(
                            (index, outlet) => MapEntry(outlet.uid, index))),
                    selectedItems: widget.vm.selectedLoomOutlets,
                    onSelectionUpdated: widget.vm.onSelectedLoomOutletsChanged,
                    mode: SelectionMode.multi,
                    child: ListView.builder(
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
                            maxSimultaneousDrags: outletVm.assigned ? 0 : null,
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
                      ? ListView.builder(
                          itemCount: widget.vm.loomVms.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _buildRow(widget.vm.loomVms[index], index);
                          })
                      : NoLoomsHoverFallback(
                          onCreateNewLoom: (outletVms) =>
                              _handleCreateNewFeederLoom(outletVms,
                                  0), // No Looms exist already so we can insert this at index 0.
                        ),
                )),
              ],
            ),
          )
        ],
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

  Widget _buildRow(LoomItemViewModel rowVm, int index) {
    return switch (rowVm) {
      LoomViewModel viewModel => Padding(
          key: Key(rowVm.loom.uid),
          padding: EdgeInsets.only(top: index != 0 ? 16 : 0),
          child: DragOverlayRegion(
            childWhenDraggingOver: ModifyExistingLoomDropTargets(
              onOutletsAdded: (outletVms) => rowVm.addOutletsToLoom(
                  rowVm.uid, outletVms.map((item) => item.uid).toSet()),
            ),
            child: LoomRowItem(
                loomVm: viewModel,
                onFocusDone: _requestSelectionFocus,
                children: viewModel.children.mapIndexed((index, cableVm) {
                  final cableWidget = buildCableRowItem(
                      vm: cableVm,
                      index: index,
                      selectedCableIds: widget.vm.selectedCableIds,
                      rowVms: widget.vm.loomVms,
                      parentLoomType: viewModel.loom.type.type,
                      requestSelectionFocusCallback: _requestSelectionFocus,
                      missingUpstreamCable: cableVm.missingUpstreamCable);
                  return LongPressDraggableProxy<CableDragData>(
                    data: CableDragData(
                      cableIds: widget.vm.selectedCableIds,
                    ),
                    feedback: Material(
                        child: Container(
                            child: SizedBox(width: 700, child: cableWidget))),
                    child:
                        _wrapSelectionListener(vm: cableVm, child: cableWidget),
                  );
                }).toList()),
          ),
        ),
      DividerViewModel divider => LoomItemDivider(
          onDropAsFeeder: (outletVms) =>
              _handleCreateNewFeederLoom(outletVms, divider.index),
          onDropAsExtension: (cableIds) =>
              _handleCreateNewExtensionLoom(cableIds, divider.index),
        ),
      _ => const Text('WOOOOPS'),
    };
  }

  void _handleCreateNewFeederLoom(
      List<OutletViewModel> droppedVms, int dividerIndex) {
    widget.vm.onCreateNewFeederLoom(
        droppedVms.map((item) => item.uid).toList(), dividerIndex);
  }

  void _handleCreateNewExtensionLoom(List<String> cableIds, int dividerIndex) {
    widget.vm.onCreateNewExtensionLoom(cableIds, dividerIndex);
  }

  void _requestSelectionFocus() {
    // TODO: Tie this to a FocusNode.
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
