import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/hoists/hoists.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistController extends StatefulWidget {
  static const List<double> columnWidths = [
    48, // Channel
    200, // Hoist Name
    200, // Location
    100, // Multi
    100, // Patch
    300, // Notes
  ];

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
                  child: Builder(builder: (context) {
                    return OutlineButton(
                        leading: const Icon(Icons.edit),
                        size: ButtonSize.small,
                        child: Text('${widget.viewModel.controller.ways} Way'),
                        onPressed: () {
                          showDropdown(
                              context: context,
                              builder: (context) => DropdownMenu(children: [
                                    const MenuLabel(
                                        child: Text('Select Controller Type')),
                                    MenuButton(
                                      child: const Text('8way'),
                                      onPressed: (_) => widget.viewModel
                                          .onControllerWaysChanged(8),
                                    ),
                                    MenuButton(
                                      child: const Text('16way'),
                                      onPressed: (_) => widget.viewModel
                                          .onControllerWaysChanged(16),
                                    ),
                                    MenuButton(
                                      child: const Text('32way'),
                                      onPressed: (_) => widget.viewModel
                                          .onControllerWaysChanged(32),
                                    ),
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
                    width: HoistController.columnWidths[0],
                    child: const Text("Channel"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: HoistController.columnWidths[1],
                    child: const Text("Hoist Name"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: HoistController.columnWidths[2],
                    child: const Text("Location"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: HoistController.columnWidths[3],
                    child: const Text("Multi"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                    width: HoistController.columnWidths[4],
                    child: const Text("Patch"),
                  ),
                  const VerticalDivider(
                    color: Colors.transparent,
                  ),
                  SizedBox(
                      width: HoistController.columnWidths[5],
                      child: const Text('Notes'))
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Column(
            children: widget.viewModel.channels
                .mapIndexed((index, channel) => _HoistChannel(
                      viewModel: channel,
                      hoistChannelDelta: widget.channelDeltas[channel.uid],
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

class _HoistChannel extends StatelessWidget {
  static const double height = 24;
  final HoistChannelViewModel viewModel;
  final void Function(int count) onHoveringOver;
  final void Function() onHoverLeave;
  final HoistChannelDelta? hoistChannelDelta;

  final bool showLandingZone;

  const _HoistChannel({
    required this.viewModel,
    required this.onHoveringOver,
    required this.onHoverLeave,
    required this.showLandingZone,
    this.hoistChannelDelta,
  });

  @override
  Widget build(BuildContext context) {
    const BorderSide hoveringBorderSide = BorderSide(
      color: Colors.green,
      width: 1,
    );

    return DiffStateOverlay(
      diff: hoistChannelDelta?.overallDiff,
      child: _wrapSelectionListener(
        viewModel: viewModel,
        child: DragTargetProxy<HoistDragData>(
            onWillAcceptWithDetails: (details) {
              onHoveringOver(details.data.viewModels.length);
              return true;
            },
            onAcceptWithDetails: (details) {
              viewModel.onHoistsLanded(
                  details.data.viewModels.map((vm) => vm.uid).toSet());
              onHoverLeave();
            },
            onLeave: (_) => onHoverLeave(),
            builder: (context, candidateData, rejectedData) {
              return Container(
                color: viewModel.selected
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
                      diff: hoistChannelDelta?.channelProperties
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
                      child: viewModel.hoist == null
                          ? const SizedBox()
                          : _wrapDragProxy(
                              child: _HoistChannelContents(
                                  viewModel: viewModel.hoist!,
                                  onClearButtonPressed:
                                      viewModel.onUnpatchHoist,
                                  delta: hoistChannelDelta?.hoistDelta),
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
    required HoistChannelViewModel viewModel,
  }) {
    if (viewModel.hoist == null) {
      return child;
    }

    return ItemSelectionListener<String>(
      itemId: viewModel.hoist!.uid,
      index: viewModel.itemIndex,
      child: child,
    );
  }

  Widget _wrapDragProxy({
    required Widget child,
    required HoistChannelViewModel viewModel,
  }) {
    return LongPressDraggableProxy<HoistDragData>(
      data: HoistDragData(
          viewModels: viewModel.selectedHoistChannelViewModels.values.toList()),
      onDragStarted: () => viewModel.onDragStarted(),
      feedback: Opacity(
          opacity: 0.25,
          child: Card(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: viewModel.selectedHoistChannelViewModels.values
                .map((itemVm) => _HoistChannelContents(
                      viewModel: itemVm,
                      onClearButtonPressed: () {},
                    ))
                .toList(),
          ))),
      child: child,
    );
  }
}

class _HoistChannelContents extends StatelessWidget {
  final HoistViewModel viewModel;
  final HoistDelta? delta;
  final void Function() onClearButtonPressed;
  const _HoistChannelContents({
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
                width: HoistController.columnWidths[1],
                child: Text(viewModel.hoist.name)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.locationName),
            child: SizedBox(
                width: HoistController.columnWidths[2],
                child: Text(viewModel.locationName)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistMultiName),
            child: SizedBox(
                width: HoistController.columnWidths[3],
                child: Text(viewModel.multi,
                    style: Theme.of(context).typography.mono)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistPatch),
            child: SizedBox(
                width: HoistController.columnWidths[4],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(viewModel.patch,
                        style: Theme.of(context).typography.mono),
                    if (viewModel.hasRootCable == false)
                      const SimpleTooltip(
                        message:
                            'Root cable missing:\nThere is no root cable (ie a feeder) existing for this channel.\nEnsure you have created a feeder cable for this outlet.',
                        child: Icon(
                          Icons.error,
                          size: 20,
                          color: Colors.orange,
                        ),
                      )
                  ],
                )),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistNote),
            child: SizedBox(
                width: HoistController.columnWidths[5],
                child: EditableTextField(
                  style: Theme.of(context)
                      .typography
                      .normal
                      .copyWith(fontStyle: FontStyle.italic),
                  value: viewModel.hoist.controllerNote,
                  onChanged: (newValue) => viewModel.onNoteChanged(newValue),
                )),
          ),
          if (isHovering)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SimpleTooltip(
                  message: 'Unpatch motor',
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
