// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

class RacksScreenViewModel {
  final Map<String, ItemData<String, PowerMultiOutletViewModel>>
      assignableItems;
  final List<PowerMultiSidebarLocation> sidebarItems;
  final List<PowerRackViewModel> powerRacks;
  final void Function() onAddPowerRack;

  RacksScreenViewModel({
    required this.assignableItems,
    required this.sidebarItems,
    required this.powerRacks,
    required this.onAddPowerRack,
  });
}

class PowerMultiOutletViewModel implements ModelCollectionMember {
  final PowerMultiOutletModel multi;
  final bool assigned;
  final LocationModel parentLocation;
  final bool selected;
  final bool hasRootCable;

  @override
  String get uid => multi.uid;

  PowerMultiOutletViewModel({
    required this.multi,
    required this.assigned,
    required this.parentLocation,
    required this.selected,
    required this.hasRootCable,
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

class PowerRackViewModel {
  final PowerRackModel rack;
  final List<PowerRackChannelViewModel> channelVms;
  final List<PowerRackTypeModel> availableTypes;
  final void Function() onDelete;
  final bool hasOverflowed;
  final void Function(String value) onNameChanged;
  final void Function(String uid) onTypeChanged;

  PowerRackViewModel({
    required this.rack,
    required this.channelVms,
    required this.availableTypes,
    required this.onDelete,
    required this.hasOverflowed,
    required this.onNameChanged,
    required this.onTypeChanged,
  });
}

class PowerRackChannelViewModel {
  final String? assignedMultiId;
  final int? assignedSelectionIndex;
  final bool isOverflowing;
  final void Function() onUnpatch;
  final void Function(Set<String> ids) onMultisLanded;

  PowerRackChannelViewModel({
    required this.assignedMultiId,
    required this.assignedSelectionIndex,
    required this.isOverflowing,
    required this.onUnpatch,
    required this.onMultisLanded,
  });
}
