import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class HoistsViewModel {
  final List<HoistItemBase> hoistItems;
  final Map<String, HoistViewModel> selectedHoistViewModels;
  final void Function(UpdateType type, Set<String> items)
      onSelectedHoistsChanged;
  final List<HoistControllerViewModel> hoistControllers;
  final Map<String, HoistViewModel> selectedHoistChannelViewModels;
  final void Function(int wayNumber) onAddMotorController;
  final void Function(UpdateType type, Set<String> items)
      onSelectedHoistChannelsChanged;
  final void Function() onDeleteSelectedHoistChannels;
  final void Function() onAddLocationButtonPressed;
  final void Function(int oldIndex, int newIndex) onHoistReorder;

  HoistsViewModel({
    required this.hoistItems,
    required this.selectedHoistViewModels,
    required this.onSelectedHoistsChanged,
    required this.hoistControllers,
    required this.selectedHoistChannelViewModels,
    required this.onAddMotorController,
    required this.onSelectedHoistChannelsChanged,
    required this.onDeleteSelectedHoistChannels,
    required this.onAddLocationButtonPressed,
    required this.onHoistReorder,
  });
}

sealed class HoistItemBase {}

class HoistViewModel extends HoistItemBase implements ModelCollectionMember {
  final HoistModel hoist;
  final void Function() onDelete;
  final void Function(String value) onNameChanged;
  final void Function(String value) onNoteChanged;
  final String locationName;
  final bool selected;
  final bool assigned;
  final String multi;
  final String patch;
  final bool hasRootCable;

  @override
  String get uid => hoist.uid;

  HoistViewModel({
    required this.hoist,
    required this.onDelete,
    required this.onNameChanged,
    required this.locationName,
    required this.selected,
    required this.assigned,
    required this.multi,
    required this.patch,
    required this.onNoteChanged,
    required this.hasRootCable,
  });
}

class HoistLocationViewModel extends HoistItemBase {
  final LocationModel location;
  final void Function() onAddHoistButtonPressed;
  final void Function() onDeleteLocation;
  final void Function() onEditLocation;

  HoistLocationViewModel({
    required this.location,
    required this.onAddHoistButtonPressed,
    required this.onDeleteLocation,
    required this.onEditLocation,
  });
}

class HoistControllerViewModel {
  final HoistControllerModel controller;
  final List<HoistChannelViewModel> channels;
  final bool hasOverflowed;
  final void Function(String newValue) onNameChanged;
  final void Function(int newValue) onControllerWaysChanged;
  final void Function() onDelete;

  HoistControllerViewModel({
    required this.controller,
    required this.channels,
    required this.hasOverflowed,
    required this.onNameChanged,
    required this.onControllerWaysChanged,
    required this.onDelete,
  });
}

class HoistChannelViewModel {
  final int number;
  final HoistViewModel? hoist;
  final void Function(Set<String> hoistIds) onHoistsLanded;
  final bool selected;
  final Map<String, HoistViewModel> selectedHoistChannelViewModels;
  final bool isOverflowing;
  final void Function() onDragStarted;
  final void Function() onUnpatchHoist;

  HoistChannelViewModel({
    required this.number,
    required this.hoist,
    required this.onHoistsLanded,
    required this.selected,
    required this.selectedHoistChannelViewModels,
    required this.isOverflowing,
    required this.onDragStarted,
    required this.onUnpatchHoist,
  });
}
