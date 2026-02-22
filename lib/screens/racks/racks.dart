import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_racks_assignment.dart';
import 'package:sidekick/screens/racks/sidebar.dart';
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

  @override
  void initState() {
    _assignmentController =
        SlotAssignmentController<String, PowerMultiOutletViewModel>(
      itemsById: widget.viewModel.assignableItems,
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
        toolbar: const Toolbar(
            child: Row(
          children: [],
        )),
        sidebar: Sidebar(
            viewModel: widget.viewModel,
            assignmentController: _assignmentController),
        body: PowerRacksAssignment(viewModel: widget.viewModel),
      ),
    );
  }
}
