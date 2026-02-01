import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';

import 'package:sidekick/screens/hoists/motor_control_assignment.dart';
import 'package:sidekick/screens/hoists/sidebar.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/attempt2.dart';
import 'package:sidekick/three_panel_scaffold.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class Hoists extends StatefulWidget {
  final HoistsViewModel viewModel;
  const Hoists({super.key, required this.viewModel});

  @override
  State<Hoists> createState() => _HoistsState();
}

class _HoistsState extends State<Hoists> {
  @override
  Widget build(BuildContext context) {
    return AssignableItemListController<String, HoistViewModel>(
      items: widget.viewModel.assignableItems,
      selectedCandidateItemIds:
          widget.viewModel.selectedHoistViewModels.keys.toSet(),
      selectedAssignedItemIds:
          widget.viewModel.selectedHoistChannelViewModels.keys.toSet(),
      onSelectedCandidateIdsChanged: (ids) =>
          widget.viewModel.onSelectedHoistsChanged(UpdateType.overwrite, ids),
      onSelectedAssignedIdsChanged: (ids) => widget.viewModel
          .onSelectedHoistChannelsChanged(UpdateType.overwrite, ids),
      child: ThreePanelScaffold(
        toolbar: Toolbar(
            child: Row(
          children: [
            SimpleTooltip(
              message: 'Unpatch selected Motor Control channels',
              child: IconButton.destructive(
                icon: const Icon(Icons.clear),
                onPressed:
                    widget.viewModel.selectedHoistChannelViewModels.isNotEmpty
                        ? widget.viewModel.onDeleteSelectedHoistChannels
                        : null,
              ),
            ),
          ],
        )),
        sidebar: Sidebar(viewModel: widget.viewModel),
        body: MotorControllerAssignment(
          viewModel: widget.viewModel,
        ),
      ),
    );
  }
}
