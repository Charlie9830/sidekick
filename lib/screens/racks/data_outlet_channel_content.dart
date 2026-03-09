import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/data_outlet_column_widths.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class DataOutletChannelContent extends StatelessWidget {
  final DataOutletViewModel viewModel;
  final void Function() onClearButtonPressed;

  const DataOutletChannelContent({
    super.key,
    required this.viewModel,
    required this.onClearButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    const divider = VerticalDivider(width: 8);

    return HoverRegionBuilder(builder: (context, isHovering) {
      return Row(
        children: [
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[1],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.patch.universe.toString(),
                    style: Theme.of(context).typography.mono),
              )),
          divider,
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[2],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.patch.name.toString(),
                    style: Theme.of(context).typography.mono),
              )),
          divider,
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[3],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.parentMulti == null ? 'Single' : 'Sneak',
                    style: Theme.of(context).typography.normal),
              )),
          divider,
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[4],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.parentMulti?.name.toString() ?? '',
                    style: Theme.of(context).typography.normal),
              )),
          divider,
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[5],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.parentMultiLineNumber?.toString() ?? '',
                    style: Theme.of(context).typography.normal),
              )),
          divider,
          SizedBox(
              width: DataOutletColumnWidths.columnWidths[6],
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(viewModel.parentLocation.name,
                    style: Theme.of(context).typography.normal),
              )),
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
