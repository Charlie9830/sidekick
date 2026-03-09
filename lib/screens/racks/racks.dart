import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_racks_assignment.dart';
import 'package:sidekick/screens/racks/sidebar.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/three_panel_scaffold.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class Racks extends StatefulWidget {
  final RacksScreenViewModel viewModel;
  const Racks({super.key, required this.viewModel});

  @override
  State<Racks> createState() => _RacksState();
}

class _RacksState extends State<Racks> {
  late final SlotAssignmentController<String, PowerMultiOutletViewModel>
      _assignmentController;
  Set<String> _selectedAvailableIds = {};
  Set<String> _selectedPlacedIds = {};

  @override
  void initState() {
    _assignmentController =
        SlotAssignmentController<String, PowerMultiOutletViewModel>(
      itemsById: widget.viewModel.assignableItems,
      onSelectionChanged: (selectedAvailableIds, selectedPlacedIds) =>
          setState(() {
        _selectedAvailableIds = selectedAvailableIds;
        _selectedPlacedIds = selectedPlacedIds;
      }),
    );

    super.initState();
  }

  @override
  void didUpdateWidget(Racks oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel.assignableItems !=
        widget.viewModel.assignableItems) {
      _assignmentController.setItems(widget.viewModel.assignableItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlotAssignmentScope<String, PowerMultiOutletViewModel>(
      controller: _assignmentController,
      child: ThreePanelScaffold(
        toolbar: Toolbar(
            child: Row(
          children: [
            SimpleTooltip(
              message: 'Unpatch selected Power Multis',
              child: IconButton.destructive(
                icon: const Icon(Icons.clear),
                onPressed: _selectedPlacedIds.isNotEmpty
                    ? () {
                        widget.viewModel
                            .onUnpatchPowerMultis(_selectedPlacedIds);
                      }
                    : null,
              ),
            ),
          ],
        )),
        sidebar: Sidebar(
            viewModel: widget.viewModel,
            assignmentController: _assignmentController),
        body: PowerRacksAssignment(viewModel: widget.viewModel),
      ),
    );
  }
}
