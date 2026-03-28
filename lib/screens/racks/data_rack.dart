import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/editable_text_field.dart';

import 'package:sidekick/screens/racks/data_outlet_channel_content.dart';
import 'package:sidekick/screens/racks/data_outlet_column_widths.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class DataRack extends StatefulWidget {
  final DataRackViewModel viewModel;

  const DataRack({
    super.key,
    required this.viewModel,
  });

  @override
  State<DataRack> createState() => _DataRackState();
}

class _DataRackState extends State<DataRack> {
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
  final DataRackViewModel viewModel;

  const _RackHeader({
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

class _ChannelArea extends StatelessWidget {
  final DataRackViewModel viewModel;
  const _ChannelArea({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
          children: viewModel.channelVms.mapIndexed((index, channelVm) {
        return Slot<String, DataOutletViewModel>(
          assignedItemId: channelVm.assignedPatchId,
          slotIndex: index,
          selectionIndex: channelVm.assignedSelectionIndex,
          slotIndexScope: viewModel.rack.uid,
          onItemsLanded: (items) {
            channelVm.onPatchesLanded(items.toSet());
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
                        ).copyWith(
                          color: switch (viewModel.rackType.dividers[index]) {
                          0 => null,
                          1 => Colors.gray.shade500,
                          2 => Colors.gray.shade400,
                          _ => null,
                        })
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: DataOutletColumnWidths.columnWidths[0],
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
                        child: DataOutletChannelContent(
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
    const divider = VerticalDivider(
      width: 8,
      color: Colors.transparent,
    );

    return DefaultTextStyle(
      style: Theme.of(context).typography.xSmall,
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[0],
              child: const Text("Outlet"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[1],
              child: const Text("Universe"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[2],
              child: const Text("Name"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[3],
              child: const Text("Type"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[4],
              child: const Text("Sneak Name"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[5],
              child: const Text("Sneak Patch"),
            ),
            divider,
            SizedBox(
              width: DataOutletColumnWidths.columnWidths[6],
              child: const Text("Location"),
            ),
          ],
        ),
      ),
    );
  }
}
