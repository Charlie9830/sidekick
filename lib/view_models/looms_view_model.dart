import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';

class LoomsViewModel {
  final void Function() onGenerateLoomsButtonPressed;
  final List<LoomScreenItemViewModel> rowVms;
  final void Function(Set<String> ids) selectCables;
  final Set<String> selectedCableIds;
  final void Function(LoomType type) onCombineCablesIntoNewLoomButtonPressed;
  final void Function() onCreateExtensionFromSelection;
  final void Function() onCombineDmxIntoSneak;
  final void Function() onSplitSneakIntoDmx;
  final void Function()? onDeleteSelectedCables;
  final void Function()? onRemoveSelectedCablesFromLoom;
  final void Function(CableType? value) onDefaultPowerMultiChanged;
  final CableType defaultPowerMulti;
  final void Function() onChangeExistingPowerMultiTypes;

  LoomsViewModel({
    required this.rowVms,
    required this.onGenerateLoomsButtonPressed,
    required this.selectCables,
    required this.selectedCableIds,
    required this.onCombineCablesIntoNewLoomButtonPressed,
    required this.onCreateExtensionFromSelection,
    required this.onCombineDmxIntoSneak,
    required this.onSplitSneakIntoDmx,
    required this.onDeleteSelectedCables,
    required this.onRemoveSelectedCablesFromLoom,
    required this.defaultPowerMulti,
    required this.onDefaultPowerMultiChanged,
    required this.onChangeExistingPowerMultiTypes,
  });
}
