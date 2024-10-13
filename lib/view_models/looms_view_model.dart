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

  LoomsViewModel({
    required this.rowVms,
    required this.onGenerateLoomsButtonPressed,
    required this.selectCables,
    required this.selectedCableIds,
    required this.onCombineCablesIntoNewLoomButtonPressed,
    required this.onCreateExtensionFromSelection,
    required this.onCombineDmxIntoSneak,
  });
}
