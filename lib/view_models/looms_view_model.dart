import 'package:sidekick/enums.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

class LoomsViewModel {
  final List<OutletViewModel> outlets;
  final Set<String> selectedLoomOutlets;
  final void Function(UpdateType updateType, Set<String> values)
      onSelectedLoomOutletsChanged;
  final List<OutletViewModel> selectedOutletVms;
  final LoomsDraggingState loomsDraggingState;
  final void Function(LoomsDraggingState draggingState)
      onLoomsDraggingStateChanged;
  final void Function(List<String> outletIds, int insertIndex,
      Set<CableActionModifier> modifiers) onCreateNewFeederLoom;
  final void Function(List<String> cableIds, int insertIndex,
      Set<CableActionModifier> modifiers) onCreateNewLoomFromExistingCables;
  final List<LoomViewModel> loomVms;
  final Set<String> selectedCableIds;
  final void Function(Set<String> ids) onSelectCables;
  final void Function(List<String> cableIds, int insertIndex,
      Set<CableActionModifier> modifiers) onCreateNewExtensionLoom;
  final void Function() onCombineSelectedDataCablesIntoSneak;
  final void Function() onSplitSneakIntoDmxPressed;
  final void Function(int oldRawIndex, int newRawIndex) onLoomReorder;
  final void Function()? onDeleteSelectedCables;
  final CableType defaultPowerMultiType;
  final void Function(CableType type) onDefaultPowerMultiTypeChanged;
  final void Function()? onChangePowerMultiTypeOfSelectedCables;
  final bool availabilityDrawOpen;
  final void Function() onShowAvailabilityDrawPressed;
  final List<LoomStockQuantityViewModel> stockVms;
  final void Function() onSetupQuantiesDrawerButtonPressed;

  LoomsViewModel({
    required this.outlets,
    required this.selectedLoomOutlets,
    required this.onSelectedLoomOutletsChanged,
    required this.selectedOutletVms,
    required this.loomsDraggingState,
    required this.onLoomsDraggingStateChanged,
    required this.onCreateNewFeederLoom,
    required this.loomVms,
    required this.selectedCableIds,
    required this.onSelectCables,
    required this.onCreateNewExtensionLoom,
    required this.onCombineSelectedDataCablesIntoSneak,
    required this.onSplitSneakIntoDmxPressed,
    required this.onLoomReorder,
    required this.onDeleteSelectedCables,
    required this.onDefaultPowerMultiTypeChanged,
    required this.defaultPowerMultiType,
    required this.onChangePowerMultiTypeOfSelectedCables,
    required this.onShowAvailabilityDrawPressed,
    required this.availabilityDrawOpen,
    required this.stockVms,
    required this.onSetupQuantiesDrawerButtonPressed,
    required this.onCreateNewLoomFromExistingCables,
  });
}

abstract class OutletViewModel {
  final String uid;
  final bool assigned;
  final int selectionIndex;

  OutletViewModel({
    required this.uid,
    required this.assigned,
    required this.selectionIndex,
  });
}

class PowerMultiOutletViewModel extends OutletViewModel {
  final PowerMultiOutletModel outlet;

  PowerMultiOutletViewModel(
      {required String uid,
      required this.outlet,
      required bool assigned,
      required int selectionIndex})
      : super(uid: uid, assigned: assigned, selectionIndex: selectionIndex);
}

class DataOutletViewModel extends OutletViewModel {
  final DataPatchModel outlet;

  DataOutletViewModel(
      {required String uid,
      required this.outlet,
      required bool assigned,
      required int selectionIndex})
      : super(uid: uid, assigned: assigned, selectionIndex: selectionIndex);
}

class HoistOutletViewModel extends OutletViewModel {
  final HoistModel outlet;

  HoistOutletViewModel(
      {required String uid,
      required this.outlet,
      required bool assigned,
      required int selectionIndex})
      : super(uid: uid, assigned: assigned, selectionIndex: selectionIndex);
}

class OutletDividerViewModel extends OutletViewModel {
  final String title;

  OutletDividerViewModel({
    required this.title,
    required String uid,
  }) : super(uid: uid, assigned: false, selectionIndex: -1);
}

class LoomStockQuantityViewModel {
  final LoomStockModel stock;
  final int inUse;

  LoomStockQuantityViewModel({
    required this.stock,
    required this.inUse,
  });
}
