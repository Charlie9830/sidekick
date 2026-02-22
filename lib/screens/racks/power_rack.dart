import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/editable_text_field.dart';

import 'package:sidekick/screens/hoists/hoist_controller_column_widths.dart';
import 'package:sidekick/screens/racks/power_multi_channel_content.dart';
import 'package:sidekick/screens/racks/power_multi_column_widths.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

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
          // Controller Header
          HoverRegionBuilder(builder: (context, isHovering) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 360,
                  child: EditableTextField(
                    onChanged: (newValue) =>
                        widget.viewModel.onNameChanged(newValue),
                    value: widget.viewModel.rack.name,
                    style: Theme.of(context).typography.large.copyWith(
                        color: widget.viewModel.hasOverflowed
                            ? Colors.amber
                            : null),
                  ),
                ),
                const Spacer(),
                if (isHovering)
                  SimpleTooltip(
                    message: "Delete controller",
                    child: IconButton.destructive(
                      size: ButtonSize.small,
                      icon: const Icon(Icons.delete),
                      onPressed: widget.viewModel.onDelete,
                    ),
                  ),
                const SizedBox(width: 8.0),
                _TypeSelectButton(viewModel: widget.viewModel),
              ],
            );
          }),

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
