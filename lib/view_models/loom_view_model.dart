import 'package:flutter/material.dart';
import 'package:sidekick/classes/permanent_composition_selection.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/cable_view_model.dart';

class LoomViewModel with DiffComparable implements ModelCollectionMember {
  final LoomModel loom;
  final int loomsOnlyIndex;
  final bool hasVariedLengthChildren;
  final String name;
  final List<CableViewModel> children;
  final void Function(String newValue) onLengthChanged;
  final void Function() onDelete;
  final void Function() onDropperToggleButtonPressed;
  final void Function() onSwitchType;
  final bool isValidComposition;
  final void Function() addSpareCablesToLoom;
  final void Function() onRepairCompositionButtonPressed;
  final void Function(String uid, Set<String> ids) addOutletsToLoom;
  final void Function(String newValue) onNameChanged;
  final void Function(String uid, Set<String> ids) onMoveCablesIntoLoom;
  final void Function(String uid, Set<String> ids) onAddCablesIntoLoomAsExtensions;
  final List<DropdownMenuEntry<PermanentCompositionSelection>> permCompEntries;
  final void Function(PermanentCompositionSelection selection)
      onChangeToSpecificComposition;

  LoomViewModel({
    required this.loom,
    required this.loomsOnlyIndex,
    required this.hasVariedLengthChildren,
    required this.children,
    required this.onLengthChanged,
    required this.onDelete,
    required this.onDropperToggleButtonPressed,
    required this.onSwitchType,
    required this.isValidComposition,
    required this.name,
    required this.addSpareCablesToLoom,
    required this.onRepairCompositionButtonPressed,
    required this.addOutletsToLoom,
    required this.onNameChanged,
    required this.onMoveCablesIntoLoom,
    required this.permCompEntries,
    required this.onChangeToSpecificComposition,
    required this.onAddCablesIntoLoomAsExtensions,
  });

  @override
  String get uid => loom.uid;

  @override
  Map<PropertyDeltaName, Object> getDiffValues() => {
        PropertyDeltaName.loomType: loom.type,
        PropertyDeltaName.name: name,
        PropertyDeltaName.hasVariedLengthChildren: hasVariedLengthChildren,
      };
}
