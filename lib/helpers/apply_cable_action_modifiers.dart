// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/helpers/cable_combiners.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

class CableActionModifierResult {
  final Map<String, CableModel> cables;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, HoistMultiModel> hoistMultis;
  final Map<String, Outlet> outlets;
  final Map<String, LocationModel> locations;
  final LoomModel loom;
  final String? permanentLoomConversionError;
  final List<CableModel> deletedCables;

  CableActionModifierResult({
    required this.cables,
    required this.dataMultis,
    required this.hoistMultis,
    required this.locations,
    required this.outlets,
    required this.loom,
    required this.permanentLoomConversionError,
    required this.deletedCables,
  });

  CableActionModifierResult copyWith({
    Map<String, CableModel>? cables,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, HoistMultiModel>? hoistMultis,
    Map<String, Outlet>? outlets,
    Map<String, LocationModel>? locations,
    LoomModel? loom,
    String? permanentLoomConversionError,
    List<CableModel>? deletedCables,
  }) {
    return CableActionModifierResult(
      cables: cables ?? this.cables,
      dataMultis: dataMultis ?? this.dataMultis,
      hoistMultis: hoistMultis ?? this.hoistMultis,
      outlets: outlets ?? this.outlets,
      locations: locations ?? this.locations,
      loom: loom ?? this.loom,
      permanentLoomConversionError:
          permanentLoomConversionError ?? this.permanentLoomConversionError,
      deletedCables: deletedCables ?? this.deletedCables,
    );
  }
}

CableActionModifierResult applyCableActionModifiers({
  required Set<CableActionModifier> modifiers,
  required Map<String, CableModel> cables,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, HoistMultiModel> hoistMultis,
  required Map<String, LocationModel> locations,
  required LoomModel loom,
  required Map<String, Outlet> outlets,
}) {
  return modifiers
      .toList()
      .sorted((a, b) =>
          a.index -
          b.index) // Sort the modifiers to ensure we act upon them in the correct order. Regardless of how they were added to the Set.
      .fold<CableActionModifierResult>(
          CableActionModifierResult(
            cables: cables,
            dataMultis: dataMultis,
            hoistMultis: hoistMultis,
            locations: locations,
            outlets: outlets,
            loom: loom,
            permanentLoomConversionError: null,
            deletedCables: [],
          ),
          (prev, modifier) => switch (modifier) {
                CableActionModifier.combineIntoMultis =>
                  _applyCombineIntoMultisAction(prev),
                CableActionModifier.convertToPermanent =>
                  _applyConvertToPermanentLoomAction(prev),
              });
}

CableActionModifierResult _applyConvertToPermanentLoomAction(
    CableActionModifierResult incoming) {
  final loomChildren = incoming.cables.values
      .where((cable) => cable.loomId == incoming.loom.uid);
  final (updatedCables, updatedLoom, error) =
      convertToPermanentLoom(loomChildren.toList(), incoming.loom);

  if (error != null) {
    return incoming.copyWith(
        permanentLoomConversionError:
            '${incoming.permanentLoomConversionError ?? ''}  /  $error');
  }

  return incoming.copyWith(
    cables: incoming.cables.clone()..addAll(updatedCables.toModelMap()),
    loom: updatedLoom,
  );
}

CableActionModifierResult _applyCombineIntoMultisAction(
    CableActionModifierResult incoming) {
  final multiActions = [
    _applyCombineIntoSneaksAction,
    _applyCombineIntoHoistMultisAction,
  ];

  return multiActions.fold(incoming, (prev, modifier) => modifier(prev));
}

CableActionModifierResult _applyCombineIntoSneaksAction(
    CableActionModifierResult incoming) {
  final sneakCombinationResult = combineDmxIntoSneak(
      cables: incoming.cables.values.toList(),
      outlets: incoming.outlets,
      existingLocations: incoming.locations);

  final cableIdsToDelete =
      sneakCombinationResult.cablesToDelete.map((cable) => cable.uid).toSet();

  return incoming.copyWith(
    cables: incoming.cables.clone()
      ..addAll(sneakCombinationResult.cables.toModelMap())
      ..removeWhere((key, value) => cableIdsToDelete.contains(
          key)), // Delete any cables that have been flagged for removal
    // Nominally these are now excess spare cables.
    deletedCables: [], // Clear the collection of Deleted cables as we have performed that action now.
    dataMultis: incoming.dataMultis.clone()
      ..addAll(sneakCombinationResult.newDataMultis.toModelMap()),
    locations: incoming.locations.clone()
      ..addAll([
        if (sneakCombinationResult.location != null)
          sneakCombinationResult.location!
      ].toModelMap()),
  );
}

CableActionModifierResult _applyCombineIntoHoistMultisAction(
    CableActionModifierResult incoming) {
  final hoistCombinationResult = combineHoistsIntoMulti(
      cables: incoming.cables.values.toList(),
      outlets: incoming.outlets,
      existingLocations: incoming.locations);

  final cableIdsToDelete =
      hoistCombinationResult.cablesToDelete.map((cable) => cable.uid).toSet();


  return incoming.copyWith(
    cables: incoming.cables.clone()
      ..addAll(hoistCombinationResult.cables.toModelMap())
      ..removeWhere((key, value) => cableIdsToDelete.contains(
          key)), // Delete any cables that have been flagged for removal
    // Nominally these are now excess spare cables.
    deletedCables: [], // Clear the collection of Deleted cables as we have performed that action now.
    hoistMultis: incoming.hoistMultis.clone()
      ..addAll(hoistCombinationResult.newHoistMultis.toModelMap()),
    locations: incoming.locations.clone()
      ..addAll([
        if (hoistCombinationResult.location != null)
          hoistCombinationResult.location!
      ].toModelMap()),
  );
}
