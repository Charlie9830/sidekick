import 'dart:io';

import 'package:sidekick/redux/models/built_in_power_rack_types.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/project_file_model.dart';
import 'package:path/path.dart' as p;

Future<ProjectFileModel> deserializeProjectFile(String path) async {
  final fileContents = await File(path).readAsString();

  const defaultFixtureState = FixtureState.initial();
  var projectData = ProjectFileModel.fromJson(fileContents);

  // Coerce Metadata Properties.
  // Project Name
  if (projectData.metadata.projectName.isEmpty) {
    projectData = projectData.copyWith(
        metadata: projectData.metadata
            .copyWith(projectName: p.basenameWithoutExtension(path)));
  }

  // Coerce PowerRackTypes
  if (projectData.powerRackTypes.isEmpty) {
    projectData = projectData.copyWith(
        powerRackTypes: BuiltInPowerRackTypes.types.values.toList());
  }

  // Coerce Power Feeds
  if (projectData.powerFeeds.isEmpty) {
    projectData = projectData.copyWith(
        powerFeeds: defaultFixtureState.powerFeeds.values.toList());
  }

  if (projectData.dataRackTypes.isEmpty) {
    projectData = projectData.copyWith(
        dataRackTypes: defaultFixtureState.dataRackTypes.values.toList());
  }

  return projectData;
}
