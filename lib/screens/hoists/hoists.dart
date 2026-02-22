import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/screens/hoists/motor_control_assignment.dart';
import 'package:sidekick/screens/hoists/sidebar.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
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
  late final SlotAssignmentController<String, HoistViewModel>
      _assignmentController;

  @override
  void initState() {
    super.initState();
    _assignmentController = SlotAssignmentController<String, HoistViewModel>(
        itemsById: widget.viewModel.assignableItems);
  }

  @override
  void didUpdateWidget(Hoists oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel.assignableItems !=
        widget.viewModel.assignableItems) {
      _assignmentController.setItems(widget.viewModel.assignableItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlotAssignmentScope<String, HoistViewModel>(
      controller: _assignmentController,
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
        sidebar: Sidebar(
            viewModel: widget.viewModel,
            assignmentController: _assignmentController),
        body: MotorControllerAssignment(
          viewModel: widget.viewModel,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _assignmentController.dispose();
    super.dispose();
  }
}
