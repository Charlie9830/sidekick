import 'package:sidekick/enums.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';

class LoomsV2ViewModel {
  final List<OutletViewModel> outlets;
  final Set<String> selectedLoomOutlets;
  final void Function(UpdateType updateType, Set<String> values)
      onSelectedLoomOutletsChanged;
  final List<OutletViewModel> selectedOutletVms;
  final LoomsDraggingState loomsDraggingState;
  final void Function(LoomsDraggingState draggingState)
      onLoomsDraggingStateChanged;
  final void Function(List<String> outletIds) onCreateNewCustomLoom;
  final void Function(List<String> outletIds) onCreateNewPermanentLoom;
  final List<LoomItemViewModel> loomVms;
  final Set<String> selectedCableIds;
  final void Function(Set<String> ids) onSelectCables;

  LoomsV2ViewModel({
    required this.outlets,
    required this.selectedLoomOutlets,
    required this.onSelectedLoomOutletsChanged,
    required this.selectedOutletVms,
    required this.loomsDraggingState,
    required this.onLoomsDraggingStateChanged,
    required this.onCreateNewCustomLoom,
    required this.onCreateNewPermanentLoom,
    required this.loomVms,
    required this.selectedCableIds,
    required this.onSelectCables,
  });
}

abstract class OutletViewModel {
  final String uid;
  final bool assigned;

  OutletViewModel({
    required this.uid,
    required this.assigned,
  });
}

class PowerMultiOutletViewModel extends OutletViewModel {
  final PowerMultiOutletModel outlet;

  PowerMultiOutletViewModel(
      {required String uid, required this.outlet, required bool assigned})
      : super(uid: uid, assigned: assigned);
}

class DataOutletViewModel extends OutletViewModel {
  final DataPatchModel outlet;

  DataOutletViewModel(
      {required String uid, required this.outlet, required bool assigned})
      : super(uid: uid, assigned: assigned);
}
