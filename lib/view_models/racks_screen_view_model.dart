// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
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
  final bool hasRootCable;

  @override
  String get uid => multi.uid;

  PowerMultiOutletViewModel({
    required this.multi,
    required this.assigned,
    required this.parentLocation,
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
  final List<PowerFeedViewModel> availablePowerFeeds;
  final void Function() onDelete;
  final bool hasOverflowed;
  final void Function(String value) onNameChanged;
  final void Function(String uid) onTypeChanged;
  final PowerFeedViewModel? powerFeed;
  final void Function(String id) updatePowerSystemId;
  final void Function() onEditPowerSystems;
  final void Function() onManagePowerSystems;
  final void Function(String feedId) onPowerFeedSelected;

  PowerRackViewModel({
    required this.rack,
    required this.channelVms,
    required this.availableTypes,
    required this.powerFeed,
    required this.onDelete,
    required this.hasOverflowed,
    required this.onNameChanged,
    required this.onTypeChanged,
    required this.updatePowerSystemId,
    required this.onEditPowerSystems,
    required this.onManagePowerSystems,
    required this.onPowerFeedSelected,
    required this.availablePowerFeeds,
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

class PowerFeedViewModel {
  final PowerFeedModel feed;
  final CurrentDraw draw;

  PowerFeedViewModel({
    required this.feed,
    required this.draw,
  });
}

class CurrentDraw {
  final double l1;
  final double l2;
  final double l3;

  double get hottest => max(max(l1, l2), l3);

  CurrentDraw(this.l1, this.l2, this.l3);

  CurrentDraw copyWith({
    double? l1,
    double? l2,
    double? l3,
  }) {
    return CurrentDraw(
      l1 ?? this.l1,
      l2 ?? this.l2,
      l3 ?? this.l3,
    );
  }

  CurrentDraw addedWith(CurrentDraw other) {
    return copyWith(l1: l1 + other.l1, l2: l2 + other.l2, l3: l3 + other.l3);
  }
}
