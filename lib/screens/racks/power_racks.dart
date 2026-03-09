import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_racks_assignment.dart';
import 'package:sidekick/screens/racks/power_racks_sidebar.dart';
import 'package:sidekick/sidebar_content_scaffold.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerRacks extends StatefulWidget {
  final RacksScreenViewModel viewModel;
  final void Function(
          Set<String> selectedAvailableIds, Set<String> selectedPlacedIds)
      onPowerMultiSelectionChanged;
  const PowerRacks({
    super.key,
    required this.viewModel,
    required this.onPowerMultiSelectionChanged,
  });

  @override
  State<PowerRacks> createState() => _PowerRacksState();
}

class _PowerRacksState extends State<PowerRacks> {
  late final SlotAssignmentController<String, PowerMultiOutletViewModel>
      _assignmentController;
  @override
  void initState() {
    _assignmentController =
        SlotAssignmentController<String, PowerMultiOutletViewModel>(
      itemsById: widget.viewModel.assignablePowerMultiItems,
      onSelectionChanged: widget.onPowerMultiSelectionChanged,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(PowerRacks oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel.assignablePowerMultiItems !=
        widget.viewModel.assignablePowerMultiItems) {
      _assignmentController
          .setItems(widget.viewModel.assignablePowerMultiItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlotAssignmentScope<String, PowerMultiOutletViewModel>(
      controller: _assignmentController,
      child: SidebarContentScaffold(
        sidebar: PowerRacksSidebar(
            viewModel: widget.viewModel,
            assignmentController: _assignmentController),
        body: PowerRacksAssignment(viewModel: widget.viewModel),
      ),
    );
  }
}
