import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class CableViewModel with DiffComparable implements ModelCollectionMember {
  final CableModel cable;
  final String locationId;
  final LabelColorModel labelColor;
  final bool isExtension;
  final int universe;
  final String label;
  final bool missingUpstreamCable;
  final String typeLabel;
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
    required this.typeLabel,
    required this.onNotesChanged,
  });

  @override
  String get uid => cable.uid;

  @override
  Map<PropertyDeltaName, Object> getDiffValues() => {
        PropertyDeltaName.cableLength: cable.length,
        PropertyDeltaName.notes: cable.notes,
        PropertyDeltaName.cableType: cable.type,
        PropertyDeltaName.isSpare: cable.isSpare,
        PropertyDeltaName.outletId: cable.outletId,
        PropertyDeltaName.isDrop: cable.isDropper,
        PropertyDeltaName.isExtension: isExtension,
        PropertyDeltaName.loomId: cable.loomId,
        PropertyDeltaName.parentMultiId: cable.parentMultiId,
        PropertyDeltaName.label: label,
        PropertyDeltaName.color: labelColor,
        PropertyDeltaName.universe: universe,

      };
}
