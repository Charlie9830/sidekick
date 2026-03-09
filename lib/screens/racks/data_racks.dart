import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/data_racks_assignment.dart';
import 'package:sidekick/screens/racks/data_racks_sidebar.dart';
import 'package:sidekick/screens/racks/power_racks_assignment.dart';
import 'package:sidekick/sidebar_content_scaffold.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class DataRacks extends StatefulWidget {
  final RacksScreenViewModel viewModel;
  final void Function(
          Set<String> selectedAvailableIds, Set<String> selectedPlacedIds)
      onDataOutletSelectionChanged;
  const DataRacks({
    super.key,
    required this.viewModel,
    required this.onDataOutletSelectionChanged,
  });

  @override
  State<DataRacks> createState() => _DataRacksState();
}

class _DataRacksState extends State<DataRacks> {
  late final SlotAssignmentController<String, DataOutletViewModel>
      _assignmentController;
  @override
  void initState() {
    _assignmentController =
        SlotAssignmentController<String, DataOutletViewModel>(
      itemsById: widget.viewModel.assignableDataItems,
      onSelectionChanged: widget.onDataOutletSelectionChanged,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(DataRacks oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel.assignableDataItems !=
        widget.viewModel.assignableDataItems) {
      _assignmentController.setItems(widget.viewModel.assignableDataItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlotAssignmentScope<String, DataOutletViewModel>(
      controller: _assignmentController,
      child: SidebarContentScaffold(
        sidebar: DataRacksSidebar(
            viewModel: widget.viewModel,
            assignmentController: _assignmentController),
        body: DataRacksAssignment(viewModel: widget.viewModel),
      ),
    );
  }
}
