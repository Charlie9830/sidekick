import 'package:sidekick/helpers/fill_cables_to_satisfy_permanent_loom.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';

(List<CableModel> updatedCables, LoomModel updatedLoom, String? error)
    convertToPermanentLoom(List<CableModel> children, LoomModel loom) {
  // Filter down to top level children only (ie we don't need to match to sneak children).
  final topLevelChildren =
      children.where((child) => child.parentMultiId.isEmpty).toList();

  final targetCompositionResult =
      PermanentLoomComposition.matchSuitablePermanent(topLevelChildren);

  if (targetCompositionResult.error != null) {
    return ([], loom, targetCompositionResult.error);
  }

  final updatedLoom = loom.copyWith(
      type: LoomTypeModel(
    type: LoomType.permanent,
    permanentComposition: targetCompositionResult.composition.name,
    length: targetCompositionResult.length,
  ));

  // Update all the children to reflect the new permanent Loom length.
  final updatedChildren = children
      .map((child) => child.copyWith(
            length: updatedLoom.type.length,
          ))
      .toList();

  final withAddedSpares = [
    ...updatedChildren,
    ...fillCablesToSatisfyPermanentLoom(updatedLoom, updatedChildren),
  ];

  return (withAddedSpares, updatedLoom, null);
}
