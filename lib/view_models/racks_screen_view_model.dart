// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_rack_type_model.dart';

class RacksScreenViewModel {
  final Map<String, PowerMultiOutletViewModel> selectedMultiOutlets;
  final void Function(UpdateType updateType, Set<String> ids)
      onSelectedPowerMultiOutletsChanged;
  final List<RackScreenItemBase> powerOutletItems;
  final List<PowerRackViewModel> powerRackVms;
  final void Function(UpdateType updateType, Set<String> ids)
      onSelectedPowerRackChannelsChanged;
  final List<PowerRackTypeViewModel> availablePowerRackTypes;

  final void Function(PowerRackTypeModel rackType) onAddPowerRack;

  RacksScreenViewModel({
    required this.selectedMultiOutlets,
    required this.powerOutletItems,
    required this.powerRackVms,
    required this.availablePowerRackTypes,
    required this.onAddPowerRack,
    required this.onSelectedPowerMultiOutletsChanged,
    required this.onSelectedPowerRackChannelsChanged,
  });
}

sealed class RackScreenItemBase {}

class RackOutletLocationViewModel extends RackScreenItemBase {
  final String locationName;

  RackOutletLocationViewModel({
    required this.locationName,
  });
}

class PowerMultiOutletViewModel extends RackScreenItemBase
    implements ModelCollectionMember {
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

class PowerRackViewModel {
  final PowerRackModel rack;
  final bool hasOverflowed;
  final void Function(String newValue) onNameChanged;
  final void Function() onDelete;
  final PowerRackTypeViewModel rackType;
  final List<PowerRackTypeViewModel> availableTypes;
  final void Function(String typeId) onTypeChanged;
  final List<PowerMultiChannelViewModel> children;

  PowerRackViewModel({
    required this.rack,
    required this.hasOverflowed,
    required this.onNameChanged,
    required this.onDelete,
    required this.rackType,
    required this.availableTypes,
    required this.onTypeChanged,
    required this.children,
  });
}

class PowerRackTypeViewModel {
  final PowerRackTypeModel type;

  PowerRackTypeViewModel({required this.type});
}

class PowerMultiChannelViewModel {
  final PowerMultiOutletViewModel? multiVm;
  final Map<String, PowerMultiOutletViewModel> selectedMultiOutlets;
  final void Function() onDragStarted;
  final void Function(Set<String> ids) onMultisLanded;
  final int number;
  final bool isOverflowing;
  final void Function()? onUnpatch;

  PowerMultiChannelViewModel({
    this.multiVm,
    required this.selectedMultiOutlets,
    required this.onDragStarted,
    required this.onMultisLanded,
    required this.number,
    required this.isOverflowing,
    required this.onUnpatch,
  });
}
