import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_multi_item.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

const double _kSidebarWidth = 360;

class PowerRacksSidebar extends StatelessWidget {
  final RacksScreenViewModel viewModel;
  final SlotAssignmentController<String, PowerMultiOutletViewModel>
      assignmentController;
  const PowerRacksSidebar({
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
          itemCount: viewModel.powerSidebarItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.powerSidebarItems[index];
            return _PowerMultiLocationItem(
              key: Key(item.location.uid),
              vm: item,
              assignmentController: assignmentController,
            );
          },
        ),
      ),
    );
  }
}

class _PowerMultiLocationItem extends StatelessWidget {
  final PowerMultiSidebarLocation vm;
  final SlotAssignmentController<String, PowerMultiOutletViewModel>
      assignmentController;

  const _PowerMultiLocationItem({
    super.key,
    required this.vm,
    required this.assignmentController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location Header
        SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vm.location.name,
                      key: Key(vm.location.uid),
                      style: Theme.of(context).typography.small),
                ],
              ),
            )),

        // Location Multis.
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          itemCount: vm.children.length,
          itemBuilder: (context, index) {
            final multi = vm.children[index];
            return AvailableItem<String, PowerMultiOutletViewModel>(
              key: Key(multi.uid),
              controller: assignmentController,
              id: multi.uid,
              selectionIndex: multi.selectionIndex,
              builder: (context, item, selected) =>
                  _contentsBuilder(context, item, selected, index),
            );
          },
        )
      ],
    );
  }

  Widget _contentsBuilder(
      BuildContext context,
      ItemData<String, PowerMultiOutletViewModel>? item,
      bool selected,
      int localIndex) {
    if (item == null) {
      return const Text("-");
    }
    return PowerMultiItem(
      assigned: item.item.assigned,
      name: item.item.multi.name,
      selected: selected,
    );
  }
}
