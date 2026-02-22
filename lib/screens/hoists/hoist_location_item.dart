import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/locations/rigging_only_tag.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistLocationItem extends StatelessWidget {
  final HoistLocationViewModel vm;
  final List<SidebarHoistItem> childHoists;
  final SlotAssignmentController<String, HoistViewModel> assignmentController;

  const HoistLocationItem({
    super.key,
    required this.vm,
    required this.childHoists,
    required this.assignmentController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location Header
        SizedBox(
          height: 48,
          child: HoverRegionBuilder(builder: (context, isHovering) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vm.location.name,
                      key: Key(vm.location.uid),
                      style: Theme.of(context).typography.small),
                  const Spacer(),
                  if (vm.location.isRiggingOnlyLocation)
                    Row(
                      children: [
                        if (isHovering)
                          Row(
                            children: [
                              IconButton.ghost(
                                icon: const Icon(Icons.delete),
                                size: ButtonSize.small,
                                onPressed: vm.onDeleteLocation,
                              ),
                              IconButton.ghost(
                                icon: const Icon(Icons.edit),
                                size: ButtonSize.small,
                                onPressed: vm.onEditLocation,
                              ),
                            ],
                          ),
                        const RiggingOnlyTag(),
                      ],
                    ),
                  SimpleTooltip(
                    message: 'Add Hoist',
                    child: IconButton.ghost(
                        icon: const Icon(Icons.add),
                        size: ButtonSize.small,
                        onPressed: vm.onAddHoistButtonPressed),
                  )
                ],
              ),
            );
          }),
        ),

        // Location Hoists.
        ReorderableList(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            onReorderStart: (index) {
              final id = childHoists.elementAtOrNull(index)?.uid;
              if (id == null) {
                return;
              }

              assignmentController.setSelectedAvailableIds({id});
            },
            itemBuilder: (context, index) {
              final hoistItem = childHoists[index];
              return AvailableItem<String, HoistViewModel>(
                key: Key(hoistItem.uid),
                controller: assignmentController,
                id: hoistItem.uid,
                selectionIndex: hoistItem.selectionIndex,
                builder: (context, item, selected) =>
                    _contentsBuilder(context, item, selected, index),
              );
            },
            itemCount: childHoists.length,
            onReorder: (oldRawIndex, newRawIndex) {
              vm.onHoistReorder(oldRawIndex, newRawIndex);
            })
      ],
    );
  }

  Widget _contentsBuilder(BuildContext context,
      ItemData<String, HoistViewModel>? item, bool selected, int localIndex) {
    if (item == null) {
      return const Text("-");
    }
    return HoistItem(
      assigned: item.item.assigned,
      name: item.item.hoist.name,
      onDelete: item.item.onDelete,
      onNameChanged: item.item.onNameChanged,
      reorderableIndex: localIndex,
      selected: selected,
    );
  }
}
