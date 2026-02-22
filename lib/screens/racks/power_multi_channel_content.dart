import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_multi_column_widths.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class PowerMultiChannelContent extends StatelessWidget {
  final PowerMultiOutletViewModel viewModel;
  final void Function() onClearButtonPressed;

  const PowerMultiChannelContent({
    super.key,
    required this.viewModel,
    required this.onClearButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    const divider = VerticalDivider(width: 16);

    return HoverRegionBuilder(builder: (context, isHovering) {
      return Row(
        children: [
          SizedBox(
              width: PowerMultiColumnWidths.columnWidths[1],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.multi.name,
                    style: Theme.of(context).typography.mono),
              )),
          divider,
          SizedBox(
              width: PowerMultiColumnWidths.columnWidths[2],
              child: Text(viewModel.parentLocation.name)),
          if (isHovering)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SimpleTooltip(
                  message: 'Unpatch multi',
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
