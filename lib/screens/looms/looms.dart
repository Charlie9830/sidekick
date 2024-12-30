import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/screens/looms/looms_toolbar.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';

class Looms extends StatefulWidget {
  final LoomsViewModel vm;
  const Looms({Key? key, required this.vm}) : super(key: key);

  @override
  State<Looms> createState() => _LoomsState();
}

class _LoomsState extends State<Looms> {
  late final FocusNode _itemSelectionFocusNode;

  @override
  void initState() {
    _itemSelectionFocusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      focusNode: _itemSelectionFocusNode,
      itemIndicies: _buildCableIndices(),
      selectedItems: widget.vm.selectedCableIds,
      onSelectionUpdated: _handleSelectionUpdate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          LoomsToolbar(
            vm: widget.vm,
            requestSelectionFocusCallback: _requestSelectionFocus,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: widget.vm.rowVms.length,
                itemBuilder: (BuildContext context, int index) {
                  final rowVm = widget.vm.rowVms[index];

                  return _buildRow(rowVm, index);
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(LoomItemViewModel rowVm, int index) {
    return switch (rowVm) {
      LocationDividerViewModel vm =>
        LocationHeaderRow(key: Key(vm.location.uid), location: vm.location),
      LoomViewModel vm => Padding(
          key: Key(rowVm.loom.uid),
          padding: EdgeInsets.only(top: index != 0 ? 16 : 0),
          child: LoomRowItem(
              loomVm: vm,
              onFocusDone: _requestSelectionFocus,
              children: vm.children
                  .mapIndexed((index, cableVm) => _wrapSelectionListener(
                      vm: cableVm,
                      child: buildCableRowItem(
                        vm: cableVm,
                        index: index,
                        selectedCableIds: widget.vm.selectedCableIds,
                        rowVms: widget.vm.rowVms,
                        parentLoomType: vm.loom.type.type,
                        requestSelectionFocusCallback: _requestSelectionFocus,
                      )))
                  .toList()),
        ),
      CableViewModel vm => _wrapSelectionListener(
          key: Key(vm.cable.uid),
          vm: vm,
          child: buildCableRowItem(
            vm: vm,
            index: index,
            selectedCableIds: widget.vm.selectedCableIds,
            rowVms: widget.vm.rowVms,
            requestSelectionFocusCallback: _requestSelectionFocus,
          )),
      _ => const Text('WOOOOPS'),
    };
  }

  void _requestSelectionFocus() {
    _itemSelectionFocusNode.requestFocus();
  }

  void _handleSelectionUpdate(UpdateType type, Set<String> ids) {
    final selectedIds = switch (type) {
      UpdateType.addIfAbsentElseRemove => widget.vm.selectedCableIds.toSet()
        ..addAllIfAbsentElseRemove(ids.cast<String>()),
      UpdateType.overwrite => ids.cast<String>(),
    };

    widget.vm.selectCables(selectedIds);
  }

  Map<String, int> _buildCableIndices() {
    return Map<String, int>.fromEntries(widget.vm.rowVms
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

  Widget _wrapSelectionListener(
      {required CableViewModel vm, required Widget child, Key? key}) {
    return ItemSelectionListener<String>(
      key: key,
      value: vm.cable.uid,
      child: child,
    );
  }
}
