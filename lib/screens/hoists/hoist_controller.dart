import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/hoists/hoists.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistController extends StatefulWidget {
  static const List<double> columnWidths = [
    48, // Channel
    200, // Hoist Name
    200, // Location
    100, // Multi
    100, // Patch
  ];

  final HoistControllerViewModel viewModel;
  const HoistController({super.key, required this.viewModel});

  @override
  State<HoistController> createState() => _HoistControllerState();
}

class _HoistControllerState extends State<HoistController> {
  Set<int> _hoveredOverRows = {};

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          HoverRegionBuilder(builder: (context, isHovering) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 200,
                  child: EditableTextField(
                    onChanged: (newValue) =>
                        widget.viewModel.onNameChanged(newValue),
                    value: widget.viewModel.controller.name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: widget.viewModel.hasOverflowed
                            ? Colors.amber
                            : null),
                  ),
                ),
                PopupMenuButton<int>(
                    tooltip: 'Change controller type',
                    onSelected: (value) =>
                        widget.viewModel.onControllerWaysChanged(value),
                    initialValue: widget.viewModel.controller.ways,
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        if (isHovering)
                          Icon(Icons.edit,
                              size: 16,
                              color: Theme.of(context).indicatorColor),
                        Text(
                          '${widget.viewModel.controller.ways}way',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 8,
                            child: Text('8way'),
                          ),
                          const PopupMenuItem(
                            value: 16,
                            child: Text('16way'),
                          ),
                          const PopupMenuItem(
                            value: 32,
                            child: Text('32way'),
                          ),
                        ]),
              ],
            );
          }),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: Theme.of(context).textTheme.labelSmall!,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.viewModel.channels.length,
            itemBuilder: (context, index) {
              final channel = widget.viewModel.channels[index];

              return _HoistChannel(
                viewModel: channel,
                showLandingZone: _hoveredOverRows.contains(index),
                onHoveringOver: (count) =>
                    _handleHoverOverChannel(index, count),
                onHoverLeave: () => _handleHoverLeave(),
              );
            },
          )
        ],
      ),
    ));
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

  final bool showLandingZone;

  const _HoistChannel({
    super.key,
    required this.viewModel,
    required this.onHoveringOver,
    required this.onHoverLeave,
    required this.showLandingZone,
  });

  @override
  Widget build(BuildContext context) {
    const BorderSide hoveringBorderSide = BorderSide(
      color: Colors.green,
      width: 1,
    );

    return _wrapSelectionListener(
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
              color: viewModel.selected ? Theme.of(context).focusColor : null,
              foregroundDecoration: BoxDecoration(
                border: showLandingZone
                    ? const Border.fromBorderSide(hoveringBorderSide)
                    : Border(
                        bottom:
                            BorderSide(width: 1, color: Colors.grey.shade800)),
              ),
              height: height,
              child: Row(
                children: [
                  SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          viewModel.number.toString(),
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: viewModel.isOverflowing
                                        ? Colors.amber
                                        : null,
                                  ),
                        ),
                      )),
                  const VerticalDivider(),
                  viewModel.hoist == null
                      ? const SizedBox()
                      : _wrapDragProxy(
                          child: _HoistChannelContents(
                              viewModel: viewModel.hoist!),
                          viewModel: viewModel,
                        ),
                ],
              ),
            );
          }),
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
      value: viewModel.hoist!.uid,
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
          child: Material(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: viewModel.selectedHoistChannelViewModels.values
                .map((itemVm) => _HoistChannelContents(viewModel: itemVm))
                .toList(),
          ))),
      child: child,
    );
  }
}

class _HoistChannelContents extends StatelessWidget {
  final HoistViewModel viewModel;
  const _HoistChannelContents({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: HoistController.columnWidths[1],
            child: Text(viewModel.hoist.name)),
        const VerticalDivider(),
        SizedBox(
            width: HoistController.columnWidths[2],
            child: Text(viewModel.locationName)),
        const VerticalDivider(),
        SizedBox(
            width: HoistController.columnWidths[3],
            child: Text(viewModel.multi)),
        const VerticalDivider(),
        SizedBox(
            width: HoistController.columnWidths[4],
            child: Text(viewModel.patch)),
      ],
    );
  }
}
