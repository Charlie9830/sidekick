import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/hoists/hoist_controller_column_widths.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistChannelContent extends StatelessWidget {
  final HoistViewModel viewModel;
  final HoistDelta? delta;
  final void Function() onClearButtonPressed;

  const HoistChannelContent({
    super.key,
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
                width: HoistControllerColumnWidths.columnWidths[1],
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(viewModel.hoist.name,
                      style: Theme.of(context).typography.mono),
                )),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.locationName),
            child: SizedBox(
                width: HoistControllerColumnWidths.columnWidths[2],
                child: Text(viewModel.locationName)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistMultiName),
            child: SizedBox(
                width: HoistControllerColumnWidths.columnWidths[3],
                child: Text(viewModel.multi,
                    style: Theme.of(context).typography.mono)),
          ),
          divider,
          DiffStateOverlay(
            diff: delta?.properties.lookup(PropertyDeltaName.hoistPatch),
            child: SizedBox(
                width: HoistControllerColumnWidths.columnWidths[4],
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
                width: HoistControllerColumnWidths.columnWidths[5],
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
                    size: ButtonSize.small,
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
