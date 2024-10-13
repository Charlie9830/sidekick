import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

class LoomScreenItemViewModel {}

class CableViewModel extends LoomScreenItemViewModel {
  final CableModel cable;
  final String locationId;
  final String labelColor;
  final bool isExtension;
  final int universe;
  final List<int> sneakUniverses;
  final String label;

  CableViewModel({
    required this.cable,
    required this.locationId,
    required this.labelColor,
    required this.isExtension,
    required this.universe,
    required this.sneakUniverses,
    required this.label,
  });
}

enum LoomDropState { isDropdown, various, isNotDropdown }

class LoomViewModel extends LoomScreenItemViewModel {
  final LoomModel loom;
  final void Function(String newValue) onNameChanged;
  final List<CableViewModel> children;
  final void Function(String newValue) onLengthChanged;
  final void Function() onDelete;
  final LoomDropState dropperState;
  final void Function() onDropperStateButtonPressed;
  final void Function() onSwitchType;
  final void Function()? addSelectedCablesToLoom;

  LoomViewModel({
    required this.loom,
    required this.children,
    required this.onNameChanged,
    required this.onLengthChanged,
    required this.onDelete,
    required this.dropperState,
    required this.onDropperStateButtonPressed,
    required this.onSwitchType,
    required this.addSelectedCablesToLoom,
  });
}

class LocationDividerViewModel extends LoomScreenItemViewModel {
  final LocationModel location;

  LocationDividerViewModel({
    required this.location,
  });
}
