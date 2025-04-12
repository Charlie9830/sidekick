import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/cable_view_model.dart';

abstract class LoomItemViewModel with DiffComparable {
  final String uid;

  LoomItemViewModel(this.uid);
}

class DividerViewModel extends LoomItemViewModel {
  final int index;

  DividerViewModel({required this.index}) : super(index.toString());

  @override
  Map<DiffPropertyName, Object> getDiffValues() {
    return {};
  }
}

class LoomViewModel extends LoomItemViewModel {
  final LoomModel loom;
  final int loomsOnlyIndex;
  final bool hasVariedLengthChildren;
  final String name;
  final List<CableViewModel> children;
  final void Function(String newValue) onLengthChanged;
  final void Function() onDelete;
  final void Function() onDropperToggleButtonPressed;
  final void Function() onSwitchType;
  final void Function()? addSelectedCablesToLoom;
  final bool isValidComposition;
  final void Function() addSpareCablesToLoom;
  final void Function() onRepairCompositionButtonPressed;
  final void Function(String uid, Set<String> ids) addOutletsToLoom;
  final void Function(String newValue) onNameChanged;
  final void Function(String uid, Set<String> ids) onMoveCablesIntoLoom;

  LoomViewModel(
      {required this.loom,
      required this.loomsOnlyIndex,
      required this.hasVariedLengthChildren,
      required this.children,
      required this.onLengthChanged,
      required this.onDelete,
      required this.onDropperToggleButtonPressed,
      required this.onSwitchType,
      required this.addSelectedCablesToLoom,
      required this.isValidComposition,
      required this.name,
      required this.addSpareCablesToLoom,
      required this.onRepairCompositionButtonPressed,
      required this.addOutletsToLoom,
      required this.onNameChanged,
      required this.onMoveCablesIntoLoom})
      : super(loom.uid);

  @override
  Map<DiffPropertyName, Object> getDiffValues() {
    return Map<DiffPropertyName, Object>.from(loom.getDiffValues())
      ..addAll({
        DiffPropertyName.name: name,
        DiffPropertyName.hasVariedLengthChildren: hasVariedLengthChildren,
      });
  }
}
