import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show ReorderableListView;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';
import 'package:sidekick/screens/racks/power_multi_outlet_item.dart';
import 'package:sidekick/screens/racks/power_rack.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class Racks extends StatefulWidget {
  final RacksScreenViewModel viewModel;
  const Racks({super.key, required this.viewModel});

  @override
  State<Racks> createState() => _RacksState();
}

class _RacksState extends State<Racks> {
  @override
  Widget build(BuildContext context) {
    return DragProxyController(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Content
          Expanded(
            child: Row(
              children: [
                _Sidebar(viewModel: widget.viewModel),
                Expanded(
                    child: _PowerRackAssignment(
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

class _PowerRackAssignment extends StatelessWidget {
  final RacksScreenViewModel viewModel;
  const _PowerRackAssignment({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      selectedItems: viewModel.selectedMultiOutlets.keys.toSet(),
      itemIndicies: Map<String, int>.fromEntries(viewModel.powerRackVms
          .map((rack) => rack.children)
          .flattened
          .where((channel) => channel.multiVm != null)
          .mapIndexed(
              (index, channel) => MapEntry(channel.multiVm!.multi.uid, index))),
      onSelectionUpdated: viewModel.onSelectedPowerRackChannelsChanged,
      child: ListView(key: motorControllersPageStorageKey, children: [
        ...viewModel.powerRackVms
            .map((vm) => PowerRack(viewModel: vm))
            .toList(),
        _PowerRackListTrailer(
            onAddButtonPressed: () => _handleAddButtonPressed(context))
      ]),
    );
  }

  void _handleAddButtonPressed(BuildContext context) async {
    final PowerRackTypeModel? rackType = await openShadSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Add Power Rack').large,
            ),
            ...viewModel.availablePowerRackTypes.map((rack) => MenuButton(
                  child: Text(rack.type.name),
                  onPressed: (context) => Navigator.of(context).pop(rack.type),
                ))
          ],
        ),
      ),
    );

    if (rackType == null) {
      return;
    }

    viewModel.onAddPowerRack(rackType);
  }
}

const double _kSidebarWidth = 360;

class _Sidebar extends StatelessWidget {
  final RacksScreenViewModel viewModel;
  const _Sidebar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      selectedItems: viewModel.selectedMultiOutlets.keys.toSet(),
      onSelectionUpdated: viewModel.onSelectedPowerMultiOutletsChanged,
      itemIndicies: Map<String, int>.fromEntries(viewModel.powerOutletItems
          .whereType<PowerMultiOutletViewModel>()
          .mapIndexed((index, item) => MapEntry(item.multi.uid, index))),
      child: SizedBox(
        width: _kSidebarWidth,
        child: Card(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.zero, topRight: Radius.zero),
          child: ListView.builder(
            key: hoistOutletPageStorageKey,
            itemCount: viewModel.powerOutletItems.length,
            itemBuilder: (context, index) {
              final item = viewModel.powerOutletItems[index];

              return switch (item) {
                PowerMultiOutletViewModel vm => ItemSelectionListener<String>(
                    key: Key(vm.multi.uid),
                    enabled: !vm.assigned,
                    value: vm.multi.uid,
                    child: _wrapDragProxy(
                        PowerMultiOutletItem(
                          vm: vm,
                        ),
                        !vm.assigned),
                  ),
                RackOutletLocationViewModel vm => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(vm.locationName,
                        style: Theme.of(context).typography.small),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _wrapDragProxy(Widget child, bool enabled) {
    if (enabled == false) {
      return child;
    }

    return LongPressDraggableProxy(
      data: PowerMultiDragData(
          viewModels: viewModel.selectedMultiOutlets.values.toList()),
      feedback: Opacity(
          opacity: 0.25,
          child: SizedBox(
              width: _kSidebarWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: viewModel.selectedMultiOutlets.values
                    .map((multiVm) => PowerMultiOutletItem(vm: multiVm))
                    .toList(),
              ))),
      child: child,
    );
  }
}

class PowerMultiDragData {
  final List<PowerMultiOutletViewModel> viewModels;

  PowerMultiDragData({required this.viewModels});
}

class _PowerRackListTrailer extends StatelessWidget {
  final void Function() onAddButtonPressed;

  const _PowerRackListTrailer({
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.text(
        onPressed: onAddButtonPressed,
        icon: const Icon(Icons.add),
        trailing: const Text('Add Rack'),
      ),
    );
  }
}
