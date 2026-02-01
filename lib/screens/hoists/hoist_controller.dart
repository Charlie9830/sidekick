import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/hoists/hoist_channel_content.dart';
import 'package:sidekick/screens/hoists/hoist_controller_column_widths.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/attempt2.dart';
import 'package:sidekick/slotted_list/slotted_list.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistController extends StatefulWidget {
  final HoistControllerViewModel viewModel;
  final PropertyDeltaSet? deltas;
  final Map<String, HoistChannelDelta> channelDeltas;

  const HoistController(
      {super.key,
      required this.viewModel,
      this.deltas,
      this.channelDeltas = const {}});

  @override
  State<HoistController> createState() => _HoistControllerState();
}

class _HoistControllerState extends State<HoistController> {
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
                  child: DiffStateOverlay(
                    diff: widget.deltas
                        ?.lookup(PropertyDeltaName.hoistControllerName),
                    child: EditableTextField(
                      onChanged: (newValue) =>
                          widget.viewModel.onNameChanged(newValue),
                      value: widget.viewModel.controller.name,
                      style: Theme.of(context).typography.large.copyWith(
                          color: widget.viewModel.hasOverflowed
                              ? Colors.amber
                              : null),
                    ),
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
                DiffStateOverlay(
                  diff: widget.deltas
                      ?.lookup(PropertyDeltaName.hoistControllerWays),
                  child: _TypeSelectButton(viewModel: widget.viewModel),
                ),
              ],
            );
          }),

          const SizedBox(height: 8),
          const _ChannelAreaHeader(),
          const SizedBox(height: 8),
          _ChannelArea(viewModel: widget.viewModel),
        ],
      )),
    );
  }
}

class _ChannelArea extends StatelessWidget {
  final HoistControllerViewModel viewModel;
  const _ChannelArea({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
          children: viewModel.channels.mapIndexed((index, channelVm) {
        return ItemSlot<String, HoistViewModel>(
          assignedItemId: channelVm.hoist?.uid,
          slotIndex: index,
          // feedbackConstraints:
          //     BoxConstraints.tightFor(width: constraints.maxWidth),
          // selectionIndex: channelVm.slottedItemSelectionIndex,
          slotIndexScope: viewModel.controller.uid,
          onItemsLanded: (items) {
            channelVm.onHoistsLanded(items.map((item) => item.uid).toSet());
          },
          builder: (context, assignedItem, selected) => SizedBox(
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.border : null,
                border: BoxBorder.fromLTRB(
                  bottom: index != viewModel.channels.length - 1
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.border,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                      width: 60,
                      child: Text(
                          assignedItem?.assignedSelectionIndex.toString() ??
                              '-')),
                  SizedBox(
                    width: HoistControllerColumnWidths.columnWidths[0],
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
                        child: HoistChannelContent(
                      viewModel: assignedItem.item,
                      onClearButtonPressed: channelVm.onUnpatchHoist,
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
  const _ChannelAreaHeader({
    super.key,
  });

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
              child: const Text("Channel"),
            ),
            const VerticalDivider(
              width: 8,
              color: Colors.transparent,
            ),
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[1],
              child: const Text("Hoist Name"),
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
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[3],
              child: const Text("Multi"),
            ),
            const VerticalDivider(
              width: 16,
              color: Colors.transparent,
            ),
            SizedBox(
              width: HoistControllerColumnWidths.columnWidths[4],
              child: const Text("Patch"),
            ),
            const VerticalDivider(
              width: 16,
              color: Colors.transparent,
            ),
            SizedBox(
                width: HoistControllerColumnWidths.columnWidths[5],
                child: const Text('Notes')),
          ],
        ),
      ),
    );
  }
}

class _TypeSelectButton extends StatelessWidget {
  const _TypeSelectButton({
    super.key,
    required this.viewModel,
  });

  final HoistControllerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return OutlineButton(
          leading: const Icon(Icons.edit),
          size: ButtonSize.small,
          child: Text('${viewModel.controller.ways} Way'),
          onPressed: () {
            showDropdown(
                context: context,
                builder: (context) => DropdownMenu(children: [
                      const MenuLabel(child: Text('Select Controller Type')),
                      MenuButton(
                        child: const Text('8way'),
                        onPressed: (_) => viewModel.onControllerWaysChanged(8),
                      ),
                      MenuButton(
                        child: const Text('16way'),
                        onPressed: (_) => viewModel.onControllerWaysChanged(16),
                      ),
                      MenuButton(
                        child: const Text('32way'),
                        onPressed: (_) => viewModel.onControllerWaysChanged(32),
                      ),
                    ]));
          });
    });
  }
}
