import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/diffing/change_overlay.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/screens/looms/editable_text_field.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class LoomRowItem extends StatefulWidget {
  final LoomViewModel loomVm;
  final List<Widget> children;
  final Set<PropertyDelta> deltas;
  final void Function() onFocusDone;

  const LoomRowItem({
    super.key,
    required this.loomVm,
    required this.children,
    required this.onFocusDone,
    this.deltas = const {},
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
                        child: Text(widget.loomVm.name,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const Spacer(),
                      if (widget.loomVm.loom.type.type == LoomType.permanent &&
                          widget.loomVm.loom.type.length == 0)
                        Row(children: [
                          SizedBox(
                              height: 36,
                              child: CableFlag(
                                text: 'Bad Length',
                                color: Colors.orange.shade700,
                              )),
                          const SizedBox(width: 8),
                        ]),
                      if (widget.loomVm.isValidComposition == false)
                        Row(
                          children: [
                            SizedBox(
                                height: 36,
                                child: CableFlag(
                                  text: 'Bad Composition',
                                  color: Colors.orange.shade700,
                                )),
                            const SizedBox(width: 8),
                          ],
                        ),
                      if (widget.loomVm.loom.type.type == LoomType.permanent)
                        const SizedBox(
                          height: 36,
                          child: CableFlag(
                            text: 'Permanent',
                            color: Colors.blueGrey,
                          ),
                        ),
                      if (widget.loomVm.loom.type.type == LoomType.custom)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 36,
                            child: CableFlag(
                              text: 'Custom',
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      if (widget.loomVm.loom.loomClass == LoomClass.extension &&
                          widget.loomVm.loom.isDrop == false)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            height: 36,
                            child: CableFlag(
                              text: 'Extension',
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      if (widget.loomVm.loom.isDrop == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            height: 36,
                            child: CableFlag(
                              text: 'Drop',
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      ChangeOverlay(
                        changeType: widget.deltas
                                .lookup(PropertyDelta.modified(
                                    DiffPropertyName.length))
                                ?.type ??
                            ChangeType.none,
                        child: SizedBox(
                          width: 42,
                          child: EditableTextField(
                            value: widget.loomVm.loom.type.length
                                .toStringAsFixed(0),
                            onChanged: (newValue) {
                              widget.onFocusDone();
                              widget.loomVm.onLengthChanged(newValue);
                            },
                            suffix: 'm',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                          widget.loomVm.loom.type.permanentComposition.isEmpty
                              ? '${widget.loomVm.hasVariedLengthChildren ? 'Staggered ' : ''}Custom'
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
                                  message: 'Add Spares',
                                  child: IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    onPressed:
                                        widget.loomVm.addSpareCablesToLoom,
                                  )),
                              Tooltip(
                                  message: 'Add selected cables',
                                  child: IconButton(
                                    icon: const Icon(Icons.move_down),
                                    onPressed:
                                        widget.loomVm.addSelectedCablesToLoom,
                                  )),
                              Tooltip(
                                  message: 'Auto repair composition',
                                  child: IconButton(
                                    icon: const Icon(Icons.build_circle),
                                    onPressed: widget
                                                .loomVm.isValidComposition ==
                                            false
                                        ? widget.loomVm
                                            .onRepairCompositionButtonPressed
                                        : null,
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
                                  color: widget.loomVm.loom.isDrop
                                      ? Colors.greenAccent
                                      : null,
                                  onPressed: widget
                                      .loomVm.onDropperToggleButtonPressed,
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
