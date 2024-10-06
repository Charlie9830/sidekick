import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

class LoomScreenItemViewModel {}

class CableViewModel extends LoomScreenItemViewModel {
  final CableModel cable;
  final String locationId;
  final String labelColor;
  final bool isExtension;

  CableViewModel({
    required this.cable,
    required this.locationId,
    required this.labelColor,
    required this.isExtension,
  });
}

class LoomViewModel extends LoomScreenItemViewModel {
  final LoomModel loom;
  final void Function(String newValue) onNameChanged;
  final List<CableViewModel> children;
  final void Function(String newValue) onLengthChanged;

  LoomViewModel({
    required this.loom,
    required this.children,
    required this.onNameChanged,
    required this.onLengthChanged,
  });
}

class LocationDividerViewModel extends LoomScreenItemViewModel {
  final LocationModel location;

  LocationDividerViewModel({
    required this.location,
  });
}