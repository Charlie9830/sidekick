// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/helpers/combine_dmx_into_sneak.dart';
import 'package:sidekick/helpers/convert_to_permanent_loom.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

class CableActionModifierResult {
  final Map<String, CableModel> cables;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, Outlet> outlets;
  final Map<String, LocationModel> locations;
  final LoomModel loom;
  final String? permanentLoomConversionError;

  CableActionModifierResult({
    required this.cables,
    required this.dataMultis,
    required this.locations,
    required this.outlets,
    required this.loom,
    required this.permanentLoomConversionError,
  });

  CableActionModifierResult copyWith({
    Map<String, CableModel>? cables,
    Map<String, DataMultiModel>? dataMultis,
    Map<String, Outlet>? outlets,
    Map<String, LocationModel>? locations,
    LoomModel? loom,
    String? permanentLoomConversionError,
  }) {
    return CableActionModifierResult(
      cables: cables ?? this.cables,
      dataMultis: dataMultis ?? this.dataMultis,
      outlets: outlets ?? this.outlets,
      locations: locations ?? this.locations,
      loom: loom ?? this.loom,
      permanentLoomConversionError:
          permanentLoomConversionError ?? this.permanentLoomConversionError,
    );
  }
}

CableActionModifierResult applyCableActionModifiers({
  required Set<CableActionModifier> modifiers,
  required Map<String, CableModel> cables,
  required Map<String, DataMultiModel> dataMultis,
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
            locations: locations,
            outlets: outlets,
            loom: loom,
            permanentLoomConversionError: null,
          ),
          (prev, modifier) => switch (modifier) {
                CableActionModifier.combineIntoSneaks =>
                  _applyCombineIntoSneaksAction(prev),
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
    cables: Map<String, CableModel>.from(incoming.cables)
      ..addAll(updatedCables.toModelMap()),
    loom: updatedLoom,
  );
}

CableActionModifierResult _applyCombineIntoSneaksAction(
    CableActionModifierResult incoming) {
  final combinationResult = combineDmxIntoSneak(
      incoming.cables.values.toList(), incoming.outlets, incoming.locations);

  return incoming.copyWith(
    cables: Map<String, CableModel>.from(incoming.cables)
      ..addAll(combinationResult.cables.toModelMap()),
    dataMultis: Map<String, DataMultiModel>.from(incoming.dataMultis)
      ..addAll(combinationResult.newDataMultis.toModelMap()),
    locations: Map<String, LocationModel>.from(incoming.locations)
      ..addAll([combinationResult.location].toModelMap()),
  );
}
