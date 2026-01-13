import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class PowerRack extends StatefulWidget {
  static const List<double> columnWidths = [
    48, // Channel
    200, // Multi name
    200, // Location
  ];

  final PowerRackViewModel viewModel;
  final PropertyDeltaSet? deltas;
  final Map<String, PowerMultiChannelDelta> outletDeltas;

  const PowerRack(
      {super.key,
      required this.viewModel,
      this.deltas,
      this.outletDeltas = const {}});

  @override
  State<PowerRack> createState() => _PowerRackState();
}

class _PowerRackState extends State<PowerRack> {
  Set<int> _hoveredOverRows = {};

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
                    diff: widget.deltas?.lookup(PropertyDeltaName.rackName),
                    child: EditableTextField(
                      onChanged: (newValue) =>
                          widget.viewModel.onNameChanged(newValue),
                      value: widget.viewModel.rack.name,
                      style: Theme.of(context).typography.large.copyWith(
                            color: widget.viewModel.hasOverflowed
                                ? Colors.amber
                                : null,
                          ),
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
                  child: Builder(builder: (context) {
                    return OutlineButton(
                        leading: const Icon(Icons.edit),
                        size: ButtonSize.small,
                        child: Text(widget.viewModel.rackType.type.name),
                        onPressed: () {
                          showDropdown(
                              context: context,
                              builder: (context) => DropdownMenu(children: [
                                    const MenuLabel(
                                        child: Text('Select Controller Type')),
                                    ...widget.viewModel.availableTypes
                                        .map((item) => MenuButton(
                                              child: Text(item.type.name),
                                              onPressed: (_) => widget.viewModel
                                                  .onTypeChanged(item.type.uid),
                                            ))
                                  ]));
                        });
                  }),
                ),
              ],
            );
          }),

          const SizedBox(height: 8),

          // Controller Content
          DefaultTextStyle(
            style: Theme.of(context).typography.xSmall,
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  SizedBox(
                    width: PowerRack.columnWidths[0],
                    child: const Text("Outlet"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: PowerRack.columnWidths[1],
                    child: const Text("Multi Name"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: PowerRack.columnWidths[2],
                    child: const Text("Location"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Column(
            children: widget.viewModel.children
                .mapIndexed((index, channel) => _PowerMultiChannel(
                      viewModel: channel,
                      powerMultiDelta:
                          widget.outletDeltas[channel.multiVm?.multi.uid],
                      showLandingZone: _hoveredOverRows.contains(index),
                      onHoveringOver: (count) =>
                          _handleHoverOverChannel(index, count),
                      onHoverLeave: () => _handleHoverLeave(),
                    ))
                .toList(),
          )
        ],
      )),
    );
  }

  void _handleHoverLeave() {
    setState(() {
      _hoveredOverRows = {};
    });
  }

  void _handleHoverOverChannel(int rowIndex, int hoveringHoistCount) {
    final hoveredOverRowIndexes =
        List.generate(hoveringHoistCount, (genIndex) => rowIndex + genIndex);

    setState(() => _hoveredOverRows = hoveredOverRowIndexes.toSet());
  }
}

class _PowerMultiChannel extends StatelessWidget {
  static const double height = 24;
  final PowerMultiChannelViewModel viewModel;
  final void Function(int count) onHoveringOver;
  final void Function() onHoverLeave;
  final PowerMultiChannelDelta? powerMultiDelta;

  final bool showLandingZone;

  const _PowerMultiChannel({
    required this.viewModel,
    required this.onHoveringOver,
    required this.onHoverLeave,
    required this.showLandingZone,
    this.powerMultiDelta,
  });

  @override
  Widget build(BuildContext context) {
    const BorderSide hoveringBorderSide = BorderSide(
      color: Colors.green,
      width: 1,
    );

    return DiffStateOverlay(
      diff: powerMultiDelta?.overallDiff,
      child: _wrapSelectionListener(
        viewModel: viewModel,
        child: DragTargetProxy<PowerMultiDragData>(
            onWillAcceptWithDetails: (details) {
              onHoveringOver(details.data.viewModels.length);
              return true;
            },
            onAcceptWithDetails: (details) {
              viewModel.onMultisLanded(
                  details.data.viewModels.map((vm) => vm.multi.uid).toSet());
              onHoverLeave();
            },
            onLeave: (_) => onHoverLeave(),
            builder: (context, candidateData, rejectedData) {
              return Container(
                color: viewModel.multiVm?.selected ?? false
                    ? Theme.of(context).colorScheme.border
                    : null,
                foregroundDecoration: BoxDecoration(
                  border: showLandingZone
                      ? const Border.fromBorderSide(hoveringBorderSide)
                      : Border(
                          bottom: BorderSide(
                              width: 1, color: Colors.gray.shade800)),
                ),
                height: height,
                child: Row(
                  children: [
                    DiffStateOverlay(
                      diff: powerMultiDelta?.channelProperties
                          .lookup(PropertyDeltaName.assignedHoistId),
                      child: SizedBox(
                          width: 48,
                          child: Center(
                            child: Text(
                              viewModel.number.toString(),
                              style: Theme.of(context).typography.mono.copyWith(
                                    color: viewModel.isOverflowing
                                        ? Colors.amber
                                        : null,
                                  ),
                            ),
                          )),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: viewModel.multiVm == null
                          ? const SizedBox()
                          : _wrapDragProxy(
                              child: _MultiChannelContents(
                                viewModel: viewModel.multiVm!,
                                onClearButtonPressed: viewModel.onUnpatch,
                                delta: powerMultiDelta?.multiDelta,
                              ),
                              viewModel: viewModel,
                            ),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }

  Widget _wrapSelectionListener({
    required Widget child,
    required PowerMultiChannelViewModel viewModel,
  }) {
    if (viewModel.multiVm == null) {
      return child;
    }

    return ItemSelectionListener<String>(
      value: viewModel.multiVm!.multi.uid,
      child: child,
    );
  }

  Widget _wrapDragProxy({
    required Widget child,
    required PowerMultiChannelViewModel viewModel,
  }) {
    return LongPressDraggableProxy<PowerMultiDragData>(
      data: PowerMultiDragData(viewModel.selectedMultiOutlets.values.toList()),
      onDragStarted: () => viewModel.onDragStarted(),
      feedback: Opacity(
          opacity: 0.25,
          child: Card(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: viewModel.selectedMultiOutlets.values
                .map((itemVm) => _MultiChannelContents(
                      viewModel: itemVm,
                      onClearButtonPressed: () {},
                    ))
                .toList(),
          ))),
      child: child,
    );
  }
}

class _MultiChannelContents extends StatelessWidget {
  final PowerMultiOutletViewModel viewModel;
  final PowerMultiOutletDelta? delta;
  final void Function()? onClearButtonPressed;

  const _MultiChannelContents({
    required this.viewModel,
    required this.onClearButtonPressed,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    const divider = VerticalDivider(width: 16);

    return HoverRegionBuilder(builder: (context, isHovering) {
      return Row(
        children: [
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistName),
            child: SizedBox(
                width: PowerRack.columnWidths[1],
                child: Text(viewModel.multi.name)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.locationName),
            child: SizedBox(
                width: PowerRack.columnWidths[2],
                child: Text(viewModel.parentLocation.name)),
          ),
          divider,
          if (isHovering)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SimpleTooltip(
                  message: 'Unpatch Multi',
                  child: IconButton.ghost(
                    icon: const Icon(Icons.clear),
                    onPressed: onClearButtonPressed,
                  ),
                ),
              ),
            )
        ],
      );
    });
  }
}

class PowerMultiDragData {
  final List<PowerMultiOutletViewModel> viewModels;

  PowerMultiDragData(this.viewModels);
}
