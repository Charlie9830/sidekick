import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class LoomHeader extends StatelessWidget {
  const LoomHeader({
    super.key,
    required this.loomVm,
    required this.reorderableListViewIndex,
    this.deltas,
  });

  final LoomViewModel loomVm;
  final int reorderableListViewIndex;
  final PropertyDeltaSet? deltas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).typography;
    final loomNameTextStyle = textTheme.large;
    final loomLengthTextStyle = textTheme.mono;
    final loomCompositionTextStyle = textTheme.small;

    return HoverRegionBuilder(builder: (context, isHovering) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              DiffStateOverlay(
                diff: deltas?.lookup(PropertyDeltaName.name),
                child: SizedBox(
                  width: 400,
                  child: EditableTextField(
                    enabled: deltas == null,
                    value: loomVm.name,
                    style: loomNameTextStyle,
                    onChanged: (newValue) => loomVm.onNameChanged(newValue),
                  ),
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
              if (loomVm.containsMotorCables)
                const SizedBox(
                  height: 28,
                  child: CableFlag(text: 'Motor', color: Colors.purple),
                ),
              if (loomVm.loom.type.type == LoomType.permanent)
                DiffStateOverlay(
                  diff: deltas?.lookup(PropertyDeltaName.loomType),
                  child: const SizedBox(
                    height: 28,
                    child: CableFlag(
                      text: 'Permanent',
                      color: Colors.neutral,
                    ),
                  ),
                ),
              if (loomVm.loom.type.type == LoomType.custom)
                DiffStateOverlay(
                  diff: deltas?.lookup(PropertyDeltaName.loomType),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      height: 28,
                      child: CableFlag(
                        text: 'Custom',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DiffStateOverlay(
                diff: deltas?.lookup(PropertyDeltaName.loomLength),
                child: IntrinsicWidth(
                  child: EditableTextField(
                    enabled: deltas == null,
                    value: loomVm.loom.type.length.toStringAsFixed(0),
                    onChanged: (newValue) {
                      loomVm.onLengthChanged(newValue);
                    },
                    suffix: 'm',
                    hintStyle: loomLengthTextStyle,
                    textAlign: TextAlign.start,
                    style: loomLengthTextStyle,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              DiffStateOverlay(
                diff: deltas?.lookup(PropertyDeltaName.permanentComposition),
                child: switch (loomVm.loom.type.type) {
                  LoomType.custom => DiffStateOverlay(
                      diff: deltas
                          ?.lookup(PropertyDeltaName.hasVariedLengthChildren),
                      child: Text(
                          loomVm.hasVariedLengthChildren
                              ? 'Staggered Custom'
                              : 'Custom',
                          style: loomCompositionTextStyle),
                    ),
                  LoomType.permanent => SizedBox(
                      width: 264,
                      child: Select<PermanentCompositionSelection>(
                        enabled: deltas == null,
                        onChanged: (value) =>
                            loomVm.onChangeToSpecificComposition(value!),
                        value: PermanentCompositionSelection.asValueSentinel(
                            loomVm.loom.type.permanentComposition),
                        itemBuilder: (context, value) => Text(value.name).small,
                        popupConstraints: const BoxConstraints(
                            minHeight:
                                280), // Ensures bottom most option is always in view.
                        popup: SelectPopup(
                            items: SelectItemList(
                          children: loomVm.permCompEntries,
                        )),
                      ),
                    ),
                },
              ),

              const Spacer(),

              // Hover Actions.
              if (deltas == null)
                AnimatedOpacity(
                    opacity: isHovering ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      children: [
                        SimpleTooltip(
                            message: 'Add Spares',
                            child: IconButton.ghost(
                              icon: const Icon(Icons.add_circle),
                              onPressed: loomVm.addSpareCablesToLoom,
                            )),
                        SimpleTooltip(
                            message: 'Auto repair composition',
                            child: IconButton.ghost(
                              icon: const Icon(Icons.healing),
                              onPressed: loomVm.isValidComposition == false
                                  ? loomVm.onRepairCompositionButtonPressed
                                  : null,
                            )),
                        SimpleTooltip(
                            message: loomVm.loom.type.type == LoomType.permanent
                                ? 'Switch to Custom'
                                : 'Switch to Permanent',
                            child: IconButton.ghost(
                              icon: loomVm.loom.type.type == LoomType.permanent
                                  ? const Icon(Icons.build_circle)
                                  : const Icon(Icons.all_inclusive),
                              onPressed: loomVm.onSwitchType,
                            )),
                        SimpleTooltip(
                          message: "Dropdown Loom",
                          child: IconButton.ghost(
                            icon: const Icon(Icons.arrow_circle_down_sharp),
                            onPressed: loomVm.onDropperToggleButtonPressed,
                          ),
                        ),
                        IconButton.ghost(
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
      );
    });
  }
}
