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

class LoomViewModel extends LoomScreenItemViewModel {
  final LoomModel loom;
  final String name;
  final List<CableViewModel> children;
  final void Function(String newValue) onLengthChanged;
  final void Function() onDelete;
  final void Function() onDropperToggleButtonPressed;
  final void Function() onSwitchType;
  final void Function()? addSelectedCablesToLoom;
  final bool isValidComposition;

  LoomViewModel({
    required this.loom,
    required this.children,
    required this.onLengthChanged,
    required this.onDelete,
    required this.onDropperToggleButtonPressed,
    required this.onSwitchType,
    required this.addSelectedCablesToLoom,
    required this.isValidComposition,
    required this.name,
  });
}

class LocationDividerViewModel extends LoomScreenItemViewModel {
  final LocationModel location;

  LocationDividerViewModel({
    required this.location,
  });
}
