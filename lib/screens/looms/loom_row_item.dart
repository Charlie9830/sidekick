import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/editable_text_field.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class LoomRowItem extends StatefulWidget {
  final LoomViewModel loomVm;
  final List<Widget> children;
  const LoomRowItem({
    super.key,
    required this.loomVm,
    required this.children,
  });

  @override
  State<LoomRowItem> createState() => _LoomRowItemState();
}

class _LoomRowItemState extends State<LoomRowItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final loomType = widget.loomVm.loom.type.type;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        HoverRegion(
          onHoverChanged: (hovering) => setState(() => _isHovering = hovering),
          child: Container(
              padding: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 400,
                        child: EditableTextField(
                          onChanged: widget.loomVm.onNameChanged,
                          value: widget.loomVm.loom.name,
                          hintText: 'Name',
                        ),
                      ),
                      const Spacer(),
                      if (widget.loomVm.isValidComposition == false)
                        SizedBox(
                            height: 36,
                            child: Chip(
                              label: const Text('Bad Composition'),
                              backgroundColor: Colors.orange.shade600,
                            )),
                      if (widget.loomVm.loom.type.type == LoomType.permanent)
                        const SizedBox(
                          height: 36,
                          child: Chip(
                            label: Text('Permanent'),
                            backgroundColor: Colors.blueGrey,
                            labelPadding: EdgeInsets.all(0),
                          ),
                        ),
                      if (widget.loomVm.loom.type.type == LoomType.custom)
                        const SizedBox(
                          height: 36,
                          child: Chip(
                            label: Text('Custom'),
                            backgroundColor: Colors.blueAccent,
                            labelPadding: EdgeInsets.all(0),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: EditableTextField(
                          value:
                              widget.loomVm.loom.type.length.toStringAsFixed(0),
                          onChanged: widget.loomVm.onLengthChanged,
                          suffix: 'm',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                          widget.loomVm.loom.type.permanentComposition.isEmpty
                              ? 'Custom'
                              : widget.loomVm.loom.type.permanentComposition,
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),

                      // Hover Actions.
                      AnimatedOpacity(
                          opacity: _isHovering ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Row(
                            children: [
                              Tooltip(
                                  message: 'Add selected cables',
                                  child: IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    onPressed:
                                        widget.loomVm.addSelectedCablesToLoom,
                                  )),
                              Tooltip(
                                  message: loomType == LoomType.permanent
                                      ? 'Switch to Custom'
                                      : 'Switch to Permanent',
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.switch_access_shortcut),
                                    onPressed: widget.loomVm.onSwitchType,
                                  )),
                              Tooltip(
                                message: "Dropdown Loom",
                                child: IconButton(
                                  icon:
                                      const Icon(Icons.arrow_circle_down_sharp),
                                  color: switch (widget.loomVm.dropperState) {
                                    LoomDropState.isNotDropdown => null,
                                    LoomDropState.isDropdown =>
                                      Colors.greenAccent,
                                    LoomDropState.various =>
                                      Colors.orangeAccent,
                                  },
                                  onPressed:
                                      widget.loomVm.onDropperStateButtonPressed,
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => widget.loomVm.onDelete()),
                            ],
                          ))
                    ],
                  )
                ],
              )),
        ),

        // Children
        if (widget.children.isEmpty)
          const Text(
            'Empty',
          ),

        // Child Items
        ...widget.children,
      ],
    );
  }
}
