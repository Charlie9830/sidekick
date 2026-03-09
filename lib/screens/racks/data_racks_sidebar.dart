import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/data_outlet_item.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

const double _kSidebarWidth = 360;

class DataRacksSidebar extends StatelessWidget {
  final RacksScreenViewModel viewModel;
  final SlotAssignmentController<String, DataOutletViewModel>
      assignmentController;
  const DataRacksSidebar({
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
            final item = viewModel.dataSidebarItems[index];
            return _DataLocationItem(
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

class _DataLocationItem extends StatelessWidget {
  final DataOutletSidebarLocation vm;
  final SlotAssignmentController<String, DataOutletViewModel>
      assignmentController;

  const _DataLocationItem({
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

        // Location Outlets.
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          itemCount: vm.children.length,
          itemBuilder: (context, index) {
            final outlet = vm.children[index];
            return AvailableItem<String, DataOutletViewModel>(
              key: Key(outlet.uid),
              controller: assignmentController,
              id: outlet.uid,
              selectionIndex: outlet.selectionIndex,
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
      ItemData<String, DataOutletViewModel>? item,
      bool selected,
      int localIndex) {
    if (item == null) {
      return const Text("-");
    }
    return DataOutletItem(
      assigned: item.item.assigned,
      name: item.item.patch.name,
      selected: selected,
      universe: item.item.patch.universe,
      parentMultiName: item.item.parentMulti?.name ?? '',
    );
  }
}
