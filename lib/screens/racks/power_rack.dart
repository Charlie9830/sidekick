import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/editable_text_field.dart';

import 'package:sidekick/screens/hoists/hoist_controller_column_widths.dart';
import 'package:sidekick/screens/racks/power_multi_channel_content.dart';
import 'package:sidekick/screens/racks/power_multi_column_widths.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/power_system_view_model.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerRack extends StatefulWidget {
  final PowerRackViewModel viewModel;

  const PowerRack({
    super.key,
    required this.viewModel,
  });

  @override
  State<PowerRack> createState() => _PowerRackState();
}

class _PowerRackState extends State<PowerRack> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          child: Column(
        children: [
          // Rack Header
          _RackHeader(viewModel: widget.viewModel),

          const SizedBox(height: 8),
          const _ChannelAreaHeader(),
          const SizedBox(height: 8),
          _ChannelArea(
            viewModel: widget.viewModel,
          ),
        ],
      )),
    );
  }
}

class _RackHeader extends StatelessWidget {
  final PowerRackViewModel viewModel;

  const _RackHeader({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 360,
          child: EditableTextField(
            onChanged: (newValue) => viewModel.onNameChanged(newValue),
            value: viewModel.rack.name,
            style: Theme.of(context)
                .typography
                .large
                .copyWith(color: viewModel.hasOverflowed ? Colors.amber : null),
          ),
        ),
        const Spacer(),
        _PowerFeedCard(
          vm: viewModel.powerFeed,
          availablePowerSystems: viewModel.availablePowerSystems,
          onPowerFeedSelected: (id) => viewModel.onPowerFeedSelected(id),
          onManagePowerSystemsButtonPressed: () =>
              viewModel.onManagePowerSystems(),
        ),
        Builder(builder: (context) {
          return IconButton.ghost(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showDropdown(
              context: context,
              builder: (context) => DropdownMenu(
                children: [
                  MenuButton(
                    subMenu: viewModel.availableTypes
                        .map((type) => MenuButton(
                              trailing: viewModel.rack.typeId == type.uid
                                  ? const Icon(Icons.check)
                                  : null,
                              child: Text(type.name),
                              onPressed: (context) =>
                                  viewModel.onTypeChanged(type.uid),
                            ))
                        .toList(),
                    child: const Text('Type'),
                  ),
                  MenuButton(
                    onPressed: (context) => viewModel.onManagePowerSystems(),
                    child: const Text('Manage Power Feeds...'),
                  ),
                  const MenuDivider(),
                  MenuButton(
                    leading: const Icon(Icons.delete),
                    child: const Text('Delete'),
                    onPressed: (context) => viewModel.onDelete(),
                  ),
                ],
              ),
            ),
          );
        })
      ],
    );
  }
}

class _PowerFeedCard extends StatelessWidget {
  final PowerFeedViewModel? vm;
  final List<PowerSystemViewModel> availablePowerSystems;
  final void Function(String feedId) onPowerFeedSelected;
  final void Function() onManagePowerSystemsButtonPressed;

  const _PowerFeedCard({
    super.key,
    required this.vm,
    required this.availablePowerSystems,
    required this.onPowerFeedSelected,
    required this.onManagePowerSystemsButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (vm == null) {
      return const SizedBox();
    }

    return Chip(
      onPressed: () => _handlePressed(context),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.electrical_services, color: Colors.gray),
              const SizedBox(width: 8.0),
              Text(
                vm!.feed.name,
                style: Theme.of(context).typography.small,
              ),
              const SizedBox(width: 32, height: 24, child: VerticalDivider()),
              _PowerMeter(capacity: vm!.feed.capacity, draw: vm!.draw),
              const SizedBox(width: 32, height: 24, child: VerticalDivider()),
              Text(vm!.parentSystemName,
                  style: Theme.of(context).typography.small),
              const SizedBox(width: 8.0),
              const Icon(Icons.location_city, color: Colors.gray),
            ],
          )
        ],
      ),
    );
  }

  void _handlePressed(BuildContext context) {
    showDropdown(
        context: context,
        builder: (context) => DropdownMenu(children: [
              ...availablePowerSystems
                  .map((system) => [
                        // System Header Button
                        MenuLabel(
                          leading: const Icon(Icons.location_city,
                              color: Colors.gray),
                          child: Text(system.system.name,
                              style: Theme.of(context).typography.semiBold),
                        ),
                        ...system.childFeeds.map((feed) => MenuButton(
                              onPressed: (context) =>
                                  onPowerFeedSelected(feed.feed.uid),
                              leading: feed.feed.uid == vm?.feed.uid
                                  ? const Center(
                                      child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    ))
                                  : null,
                              trailing: Text('${feed.feed.capacity}A',
                                  style: Theme.of(context).typography.light),
                              child: Text(feed.feed.name),
                            )),
                      ])
                  .flattened,
              const MenuDivider(),
              MenuButton(
                child: const Text("Manage Power Systems..."),
                onPressed: (context) => onManagePowerSystemsButtonPressed(),
              )
            ]));
  }
}

class _PowerMeter extends StatelessWidget {
  final CurrentDraw draw;
  final int capacity;

  const _PowerMeter({super.key, required this.draw, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final hottest = draw.hottest;
    final loadPercent = (hottest / capacity) * 100;

    final textColor = switch (loadPercent) {
      double.infinity => Colors.white,
      >= 100 => Colors.red,
      >= 75 => Colors.amber,
      _ => Colors.white,
    };

    return Stack(
      children: [
        Text(
          '${hottest.round()}A / ${capacity}A',
          style: Theme.of(context).typography.bold.copyWith(color: textColor),
        ),
      ],
    );
  }
}

class _ChannelArea extends StatelessWidget {
  final PowerRackViewModel viewModel;
  const _ChannelArea({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
          children: viewModel.channelVms.mapIndexed((index, channelVm) {
        return Slot<String, PowerMultiOutletViewModel>(
          assignedItemId: channelVm.assignedMultiId,
          slotIndex: index,
          selectionIndex: channelVm.assignedSelectionIndex,
          slotIndexScope: viewModel.rack.uid,
          onItemsLanded: (items) {
            channelVm.onMultisLanded(items.toSet());
          },
          builder: (context, assignedItem, selected) => SizedBox(
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.border : null,
                border: BoxBorder.fromLTRB(
                  bottom: index != viewModel.channelVms.length - 1
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.border,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: PowerMultiColumnWidths.columnWidths[0],
                    child: Center(
                      child: Text((index + 1).toString(),
                          style: channelVm.isOverflowing
                              ? Theme.of(context).typography.normal.copyWith(
                                    color: channelVm.isOverflowing
                                        ? Colors.amber
                                        : null,
                                  )
                              : Theme.of(context).typography.extraLight),
                    ),
                  ),
                  const VerticalDivider(),
                  if (assignedItem != null)
                    Expanded(
                        child: PowerMultiChannelContent(
                      viewModel: assignedItem.item,
                      onClearButtonPressed: channelVm.onUnpatch,
                    ))
                ],
              ),
            ),
          ),
        );
      }).toList());
    });
  }
}

class _ChannelAreaHeader extends StatelessWidget {
  const _ChannelAreaHeader();

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).typography.xSmall,
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[0],
              child: const Text("Outlet"),
            ),
            const VerticalDivider(
              width: 8,
              color: Colors.transparent,
            ),
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[1],
              child: const Text("Multi Name"),
            ),
            const VerticalDivider(
              width: 8,
              color: Colors.transparent,
            ),
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[2],
              child: const Text("Location"),
            ),
            const VerticalDivider(
              width: 16,
              color: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelectButton extends StatelessWidget {
  const _TypeSelectButton({
    required this.viewModel,
  });

  final PowerRackViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return OutlineButton(
          leading: const Icon(Icons.edit),
          size: ButtonSize.small,
          child: const Text('Change Type'),
          onPressed: () {
            showDropdown(
                context: context,
                builder: (context) => DropdownMenu(children: [
                      const MenuLabel(child: Text('Select Rack Type')),
                      ...viewModel.availableTypes.map((rackType) => MenuButton(
                            child: Text(rackType.name),
                            onPressed: (context) =>
                                viewModel.onTypeChanged(rackType.uid),
                          ))
                    ]));
          });
    });
  }
}
