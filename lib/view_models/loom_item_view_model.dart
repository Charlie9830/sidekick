import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

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

class CableViewModel extends LoomItemViewModel {
  final CableModel cable;
  final String locationId;
  final String labelColor;
  final bool isExtension;
  final int universe;
  final String label;
  final void Function(String newValue) onLengthChanged;

  CableViewModel({
    required this.cable,
    required this.locationId,
    required this.labelColor,
    required this.isExtension,
    required this.universe,
    required this.label,
    required this.onLengthChanged,
  }) : super(cable.uid);

  @override
  Map<DiffPropertyName, Object> getDiffValues() {
    return Map<DiffPropertyName, Object>.from(cable.getDiffValues())
      ..addAll({
        DiffPropertyName.isExtension: isExtension,
        DiffPropertyName.locationId: locationId,
        DiffPropertyName.label: label,
      });
  }
}

class LoomViewModel extends LoomItemViewModel {
  final LoomModel loom;
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

  LoomViewModel({
    required this.loom,
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
  }) : super(loom.uid);

  @override
  Map<DiffPropertyName, Object> getDiffValues() {
    return Map<DiffPropertyName, Object>.from(loom.getDiffValues())
      ..addAll({
        DiffPropertyName.name: name,
        DiffPropertyName.hasVariedLengthChildren: hasVariedLengthChildren,
      });
  }
}

class LocationDividerViewModel extends LoomItemViewModel {
  final LocationModel location;

  LocationDividerViewModel({
    required this.location,
  }) : super(location.uid);

  @override
  Map<DiffPropertyName, Object> getDiffValues() {
    return Map<DiffPropertyName, Object>.from(location.getDiffValues())
      ..addAll({});
  }
}
