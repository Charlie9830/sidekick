import 'dart:io';

import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

Future<ProjectFileMetadataModel> serializeProjectFile(
    AppState state, String targetPath) async {
  final now = DateTime.now();

  // Create a new Metadata object with changes applied.
  final existingMetadata = state.fileState.projectMetadata;
  final updatedMetadata = existingMetadata.copyWith(
    fileVersion: kProjectFileVersion,
    modified: now.toIso8601String(),
    created: existingMetadata.created.isEmpty
        ? now.toIso8601String()
        : existingMetadata.created,
  );

  // Package together.
  final projectFile = ProjectFileModel(
    metadata: updatedMetadata,
    fixtures: state.fixtureState.fixtures.values.toList(),
    balanceTolerance: state.fixtureState.balanceTolerance,
    dataMultis: state.fixtureState.dataMultis.values.toList(),
    dataPatches: state.fixtureState.dataPatches.values.toList(),
    locations: state.fixtureState.locations.values.toList(),
    powerMultiOutlets: state.fixtureState.powerMultiOutlets.values.toList(),
    maxSequenceBreak: state.fixtureState.maxSequenceBreak,
    looms: state.fixtureState.looms.values.toList(),
    cables: state.fixtureState.cables.values.toList(),
    defaultPowerMulti: state.fixtureState.defaultPowerMulti,
    loomStock: state.fixtureState.loomStock.values.toList(),
    fixtureTypes: state.fixtureState.fixtureTypes.values.toList(),
  );

  final json = projectFile.toJson();

  await File(targetPath).writeAsString(json);

  return updatedMetadata;
}
