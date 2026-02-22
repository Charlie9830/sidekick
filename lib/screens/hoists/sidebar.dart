import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/hoists/hoist_location_item.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

const double _kSidebarWidth = 360;

class Sidebar extends StatelessWidget {
  final HoistsViewModel viewModel;
  final SlotAssignmentController<String, HoistViewModel> assignmentController;
  const Sidebar({
    super.key,
    required this.viewModel,
    required this.assignmentController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSidebarWidth,
      child: Card(
        padding: EdgeInsets.zero,
        child: ListView.builder(
          itemCount: viewModel.sidebarItems.length + 1,
          itemBuilder: (context, index) {
            if (viewModel.sidebarItems.isEmpty ||
                index == viewModel.sidebarItems.length) {
              return Center(
                child: TextButton(
                    leading: const Icon(Icons.add),
                    onPressed: viewModel.onAddLocationButtonPressed,
                    child: const Text('Add Rigging Location')),
              );
            }

            final item = viewModel.sidebarItems[index];

            return HoistLocationItem(
                vm: item.locationVm,
                assignmentController: assignmentController,
                childHoists: item.associatedHoists);
          },
        ),
      ),
    );
  }
}
