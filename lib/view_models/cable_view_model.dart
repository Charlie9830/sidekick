import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';

class CableViewModel {
  final CableModel cable;
  final String locationId;
  final LabelColorModel labelColor;
  final bool isExtension;
  final int universe;
  final String label;
  final bool missingUpstreamCable;
  final int localNumber;
  final void Function(String newValue) onLengthChanged;
  final void Function(String newValue) onNotesChanged;

  CableViewModel({
    required this.cable,
    required this.locationId,
    required this.labelColor,
    required this.isExtension,
    required this.universe,
    required this.label,
    required this.onLengthChanged,
    required this.missingUpstreamCable,
    required this.localNumber,
    required this.onNotesChanged,
  });
}
