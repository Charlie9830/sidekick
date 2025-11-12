import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/hoists/hoist_controller.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/hoists/hoist_location_item.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class Hoists extends StatefulWidget {
  final HoistsViewModel viewModel;
  const Hoists({super.key, required this.viewModel});

  @override
  State<Hoists> createState() => _HoistsState();
}

class _HoistsState extends State<Hoists> {
  @override
  Widget build(BuildContext context) {
    return DragProxyController(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Toolbar(
              child: Row(
            children: [
              Tooltip(
                message: 'Unpatch selected Motor Control channels',
                child: IconButton.outlined(
                  icon: const Icon(Icons.clear),
                  onPressed:
                      widget.viewModel.selectedHoistChannelViewModels.isNotEmpty
                          ? widget.viewModel.onDeleteSelectedHoistChannels
                          : null,
                ),
              ),
            ],
          )),

          // Content
          Expanded(
            child: Row(
              children: [
                _Sidebar(viewModel: widget.viewModel),
                Expanded(
                    child: _MotorControllerAssignment(
                  viewModel: widget.viewModel,
                )),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MotorControllerAssignment extends StatelessWidget {
  final HoistsViewModel viewModel;
  const _MotorControllerAssignment({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      selectedItems: viewModel.selectedHoistChannelViewModels.keys.toSet(),
      itemIndicies: Map<String, int>.fromEntries(viewModel.hoistControllers
          .map((controller) => controller.channels)
          .flattened
          .where((channel) => channel.hoist != null)
          .mapIndexed((index, channel) => MapEntry(channel.hoist!.uid, index))),
      onSelectionUpdated: viewModel.onSelectedHoistChannelsChanged,
      child: ListView(
        key: motorControllersPageStorageKey,
        children: [
        ...viewModel.hoistControllers
            .map((vm) => HoistController(viewModel: vm))
            .toList(),
        _HoistControllerListTrailer(
            onAddButtonPressed: () => _handleAddButtonPressed(context))
      ]),
    );
  }

  void _handleAddButtonPressed(BuildContext context) async {
    final int? ways = await showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            TextButton(
              child: const Text('8 way'),
              onPressed: () => Navigator.of(context).pop(8),
            ),
            TextButton(
              child: const Text('16 way'),
              onPressed: () => Navigator.of(context).pop(16),
            ),
            TextButton(
              child: const Text('32 way'),
              onPressed: () => Navigator.of(context).pop(32),
            ),
          ],
        ),
      ),
    );

    if (ways == null) {
      return;
    }

    viewModel.onAddMotorController(ways);
  }
}

const double _kSidebarWidth = 360;

class _Sidebar extends StatelessWidget {
  final HoistsViewModel viewModel;
  const _Sidebar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      selectedItems: viewModel.selectedHoistViewModels.keys.toSet(),
      onSelectionUpdated: viewModel.onSelectedHoistsChanged,
      itemIndicies: Map<String, int>.fromEntries(viewModel.hoistItems
          .whereType<HoistViewModel>()
          .mapIndexed((index, item) => MapEntry(item.hoist.uid, index))),
      child: SizedBox(
        width: _kSidebarWidth,
        child: Card(
          child: ReorderableListView.builder(
              key: hoistOutletPageStorageKey,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) =>
                  viewModel.onHoistReorder(oldIndex, newIndex),
              itemCount: viewModel.hoistItems.length,
              itemBuilder: (context, index) {
                final item = viewModel.hoistItems[index];

                return switch (item) {
                  HoistLocationViewModel vm =>
                    HoistLocationItem(key: Key(vm.location.uid), vm: vm),
                  HoistViewModel vm => ItemSelectionListener<String>(
                      key: Key(vm.hoist.uid),
                      enabled: !vm.assigned,
                      value: vm.hoist.uid,
                      child: _wrapDragProxy(
                          HoistItem(
                            vm: vm,
                            reorderableIndex: index,
                          ),
                          !vm.assigned),
                    ),
                };
              },
              footer: Center(
                  child: TextButton.icon(
                icon: Icon(Icons.add_circle),
                label: Text('Add Rigging Location'),
                onPressed: viewModel.onAddLocationButtonPressed,
              ))),
        ),
      ),
    );
  }

  Widget _wrapDragProxy(Widget child, bool enabled) {
    if (enabled == false) {
      return child;
    }

    return LongPressDraggableProxy(
        data: HoistDragData(
            viewModels: viewModel.selectedHoistViewModels.values.toList()),
        feedback: Opacity(
          opacity: 0.25,
          child: Material(
              child: SizedBox(
            width: _kSidebarWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: viewModel.selectedHoistViewModels.values
                  .map((hoistVm) => HoistItem(
                        vm: hoistVm,
                        reorderableIndex: 0,
                      ))
                  .toList(),
            ),
          )),
        ),
        child: child);
  }
}

class HoistDragData {
  final List<HoistViewModel> viewModels;

  HoistDragData({required this.viewModels});
}

class _HoistControllerListTrailer extends StatelessWidget {
  final void Function() onAddButtonPressed;

  const _HoistControllerListTrailer({
    super.key,
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onAddButtonPressed,
        icon: const Icon(Icons.add),
        label: const Text('Add Motor Controller'),
      ),
    );
  }
}
