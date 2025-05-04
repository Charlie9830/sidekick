import 'package:flutter/material.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class LoomHeader extends StatelessWidget {
  const LoomHeader({
    super.key,
    required this.loomVm,
    required this.reorderableListViewIndex,
  });

  final LoomViewModel loomVm;
  final int reorderableListViewIndex;

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return Container(
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
                    value: loomVm.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    onChanged: (newValue) => loomVm.onNameChanged(newValue),
                  ),
                ),
                const Spacer(),
                if (loomVm.loom.type.type == LoomType.permanent &&
                    loomVm.loom.type.length == 0)
                  Row(children: [
                    SizedBox(
                        height: 36,
                        child: CableFlag(
                          text: 'Bad Length',
                          color: Colors.orange.shade700,
                        )),
                    const SizedBox(width: 8),
                  ]),
                if (loomVm.isValidComposition == false)
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
                if (loomVm.loom.type.type == LoomType.permanent)
                  const SizedBox(
                    height: 28,
                    child: CableFlag(
                      text: 'Permanent',
                      color: Colors.blueGrey,
                    ),
                  ),
                if (loomVm.loom.type.type == LoomType.custom)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      height: 28,
                      child: CableFlag(
                        text: 'Custom',
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: EditableTextField(
                    value: loomVm.loom.type.length.toStringAsFixed(0),
                    onChanged: (newValue) {
                      loomVm.onLengthChanged(newValue);
                    },
                    suffix: 'm',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 16),

                switch (loomVm.loom.type.type) {
                  LoomType.custom => Text(
                      loomVm.hasVariedLengthChildren
                          ? 'Staggered Custom'
                          : 'Custom',
                      style: Theme.of(context).textTheme.titleSmall),
                  LoomType.permanent =>
                    DropdownMenu<PermanentCompositionSelection>(
                      onSelected: (newValue) =>
                          loomVm.onChangeToSpecificComposition(newValue!),
                      enableFilter: false,
                      enableSearch: false,
                      textStyle: Theme.of(context).textTheme.titleSmall,
                      initialSelection:
                          PermanentCompositionSelection.asValueSentinel(
                              loomVm.loom.type.permanentComposition),
                      dropdownMenuEntries: loomVm.permCompEntries,
                    )
                },

                const Spacer(),

                // Hover Actions.
                AnimatedOpacity(
                    opacity: isHovering ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      children: [
                        Tooltip(
                            message: 'Add Spares',
                            child: IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: loomVm.addSpareCablesToLoom,
                            )),
                        Tooltip(
                            message: 'Auto repair composition',
                            child: IconButton(
                              icon: const Icon(Icons.healing),
                              onPressed: loomVm.isValidComposition == false
                                  ? loomVm.onRepairCompositionButtonPressed
                                  : null,
                            )),
                        Tooltip(
                            message: loomVm.loom.type.type == LoomType.permanent
                                ? 'Switch to Custom'
                                : 'Switch to Permanent',
                            child: IconButton(
                              icon: loomVm.loom.type.type == LoomType.permanent
                                  ? const Icon(Icons.build_circle)
                                  : const Icon(Icons.all_inclusive),
                              onPressed: loomVm.onSwitchType,
                            )),
                        Tooltip(
                          message: "Dropdown Loom",
                          child: IconButton(
                            icon: const Icon(Icons.arrow_circle_down_sharp),
                            onPressed: loomVm.onDropperToggleButtonPressed,
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => loomVm.onDelete()),
                        ReorderableDragStartListener(
                          index: reorderableListViewIndex,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ))
              ],
            )
          ],
        ),
      );
    });
  }
}
