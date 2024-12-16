import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/screens/looms/power_multi_selector.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';
import 'package:sidekick/widgets/toolbar.dart';

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
          Toolbar(
            child: Row(
              children: [
                ElevatedButton.icon(
                    onPressed: widget.vm.onGenerateLoomsButtonPressed,
                    icon: const Icon(Icons.cable),
                    label: const Text('Generate')),
                OutlinedButton.icon(
                  onPressed: () => widget.vm
                      .onCombineCablesIntoNewLoomButtonPressed(
                          LoomType.permanent),
                  icon: const Icon(Icons.add),
                  label: const Text('Permanent'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => widget.vm
                      .onCombineCablesIntoNewLoomButtonPressed(LoomType.custom),
                  icon: const Icon(Icons.add),
                  label: const Text('Custom'),
                ),
                const VerticalDivider(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Extension'),
                  onPressed: widget.vm.onCreateExtensionFromSelection,
                ),
                const VerticalDivider(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Cable',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Remove from Loom',
                          child: IconButton(
                            icon: const Icon(Icons.exit_to_app),
                            onPressed: widget.vm.onRemoveSelectedCablesFromLoom,
                          ),
                        ),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: widget.vm.onDeleteSelectedCables,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    )
                  ],
                ),
                const VerticalDivider(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sneak',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: 'Combine',
                          child: IconButton(
                            icon: const Icon(Icons.merge),
                            onPressed: widget.vm.onCombineDmxIntoSneak,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Split',
                          child: IconButton(
                            icon: const Icon(Icons.call_split),
                            onPressed: widget.vm.onSplitSneakIntoDmx,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(width: 16),
                PowerMultiSelector(
                  onChanged: (type) {
                    _requestSelectionFocus();
                    widget.vm.onDefaultPowerMultiChanged(type);
                  },
                  value: widget.vm.defaultPowerMulti,
                  onChangedExistingPressed:
                      widget.vm.onChangeExistingPowerMultiTypes,
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: widget.vm.rowVms.length,
                itemBuilder: (BuildContext context, int index) {
                  final rowVm = widget.vm.rowVms[index];

                  return switch (rowVm) {
                    LocationDividerViewModel vm => LocationHeaderRow(
                        key: Key(vm.location.uid), location: vm.location),
                    LoomViewModel vm => Padding(
                        key: Key(rowVm.loom.uid),
                        padding: EdgeInsets.only(top: index != 0 ? 16 : 0),
                        child: LoomRowItem(
                            loomVm: vm,
                            onFocusDone: _requestSelectionFocus,
                            children: vm.children
                                .mapIndexed(
                                    (index, cableVm) => _wrapSelectionListener(
                                        vm: cableVm,
                                        child: CableRowItem(
                                          cable: cableVm.cable,
                                          labelColor: cableVm.labelColor,
                                          showTopBorder: index == 0,
                                          isSelected: widget.vm.selectedCableIds
                                              .contains(cableVm.cable.uid),
                                          hideLength: vm.loom.type.type ==
                                                  LoomType.permanent ||
                                              cableVm.cable.parentMultiId
                                                  .isNotEmpty,
                                          dmxUniverse: cableVm.universe,
                                          label: cableVm.label,
                                          onLengthChanged: (newValue) {
                                            cableVm.onLengthChanged(newValue);
                                            _requestSelectionFocus();
                                          },
                                        )))
                                .toList()),
                      ),
                    CableViewModel vm => _wrapSelectionListener(
                        key: Key(vm.cable.uid),
                        vm: vm,
                        child: CableRowItem(
                          cable: vm.cable,
                          labelColor: vm.labelColor,
                          isSelected:
                              widget.vm.selectedCableIds.contains(vm.cable.uid),
                          showTopBorder: index == 0 ||
                              widget.vm.rowVms[index - 1] is! CableViewModel,
                          dmxUniverse: vm.universe,
                          label: rowVm.label,
                          onLengthChanged: (newValue) {
                            vm.onLengthChanged(newValue);
                            _requestSelectionFocus();
                          },
                          hideLength: vm.cable.parentMultiId.isNotEmpty,
                        )),
                    _ => const Text('WOOOOPS'),
                  };
                },
              ),
            ),
          )
        ],
      ),
    );
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
