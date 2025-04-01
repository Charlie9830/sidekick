import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/screens/looms_v2/drag_data.dart';
import 'package:sidekick/screens/looms_v2/loom_item_divider.dart';
import 'package:sidekick/screens/looms_v2/new_loom_drop_target_overlay.dart';
import 'package:sidekick/screens/looms_v2/no_looms_hover_fallback.dart';
import 'package:sidekick/screens/looms_v2/outlet_list_tile.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Toolbar(child: Text('Tools')),
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

                        final listTile = OutletListTile(
                            isSelected: widget.vm.selectedLoomOutlets
                                .contains(outletVm.uid),
                            key: Key(outletVm.uid),
                            vm: outletVm);

                        return Draggable<DragData>(
                          maxSimultaneousDrags: outletVm.assigned ? 0 : null,
                          data: OutletDragData(outletVms: {
                            outletVm,
                            ...widget.vm.selectedOutletVms,
                          }),
                          onDragStarted: _handleDragStart,
                          onDragCompleted: _handleDragEnd,
                          onDraggableCanceled: _handleDragCancelled,
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
                        onCustomDrop: _handleCreateNewCustomLoomDrop,
                        onPermanentDrop: _handleCreateNewPermanentLoomDrop),
              )),
            ],
          ),
        )
      ],
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
        .map((rowVm) {
          if (rowVm is CableViewModel) {
            return [rowVm.cable.uid];
          }

          if (rowVm is LoomViewModel) {
            return rowVm.children.map((child) => child.cable.uid).toList();
          }

          return null;
        })
        .expand((i) => i ?? <String>[])
        .mapIndexed((index, id) => MapEntry(id, index)));
  }

  Widget _buildRow(LoomItemViewModel rowVm, int index) {
    return switch (rowVm) {
      LocationDividerViewModel viewModel => LocationHeaderRow(
          key: Key(viewModel.location.uid), location: viewModel.location),
      LoomViewModel viewModel => Padding(
          key: Key(rowVm.loom.uid),
          padding: EdgeInsets.only(top: index != 0 ? 16 : 0),
          child: LoomRowItem(
              loomVm: viewModel,
              onFocusDone: _requestSelectionFocus,
              children: viewModel.children
                  .mapIndexed((index, cableVm) => _wrapSelectionListener(
                      vm: cableVm,
                      child: buildCableRowItem(
                        vm: cableVm,
                        index: index,
                        selectedCableIds: widget.vm.selectedCableIds,
                        rowVms: widget.vm.loomVms,
                        parentLoomType: viewModel.loom.type.type,
                        requestSelectionFocusCallback: _requestSelectionFocus,
                      )))
                  .toList()),
        ),
      CableViewModel viewModel => _wrapSelectionListener(
          key: Key(viewModel.cable.uid),
          vm: viewModel,
          child: buildCableRowItem(
            vm: viewModel,
            index: index,
            selectedCableIds: widget.vm.selectedCableIds,
            rowVms: widget.vm.loomVms,
            requestSelectionFocusCallback: _requestSelectionFocus,
          )),
      DividerViewModel divider => LoomItemDivider(
          onCustomDrop: _handleCreateNewCustomLoomDrop,
          onPermanentDrop: _handleCreateNewPermanentLoomDrop),
      _ => const Text('WOOOOPS'),
    };
  }

  void _handleCreateNewCustomLoomDrop(List<OutletViewModel> droppedVms) {
    widget.vm
        .onCreateNewCustomLoom(droppedVms.map((item) => item.uid).toList());
  }

  void _handleCreateNewPermanentLoomDrop(List<OutletViewModel> droppedVms) {
    widget.vm
        .onCreateNewPermanentLoom(droppedVms.map((item) => item.uid).toList());
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

  void _handleDragStart() {
    widget.vm.onLoomsDraggingStateChanged(LoomsDraggingState.outletDragging);
  }

  void _handleDragEnd() {
    widget.vm.onLoomsDraggingStateChanged(LoomsDraggingState.idle);
  }

  void _handleDragCancelled(Velocity velocity, Offset offset) {
    _handleDragEnd();
  }
}
