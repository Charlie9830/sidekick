// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

class RacksScreenViewModel {
  final Map<String, ItemData<String, PowerMultiOutletViewModel>>
      assignableItems;
  final List<PowerMultiSidebarLocation> sidebarItems;

  RacksScreenViewModel({
    required this.assignableItems,
    required this.sidebarItems,
  });
}

class PowerMultiOutletViewModel implements ModelCollectionMember {
  final PowerMultiOutletModel multi;
  final bool assigned;
  final LocationModel parentLocation;
  final bool selected;

  @override
  String get uid => multi.uid;

  PowerMultiOutletViewModel({
    required this.multi,
    required this.assigned,
    required this.parentLocation,
    required this.selected,
  });
}

class PowerMultiSidebarLocation {
  final LocationModel location;
  final List<PowerMultiSidebarItem> children;

  PowerMultiSidebarLocation({
    required this.location,
    required this.children,
  });
}

class PowerMultiSidebarItem {
  final String uid;
  final int selectionIndex;

  PowerMultiSidebarItem({
    required this.uid,
    required this.selectionIndex,
  });
}
