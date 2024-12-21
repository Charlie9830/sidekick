import 'dart:io';

import 'package:sidekick/serialization/project_file_model.dart';
import 'package:path/path.dart' as p;

Future<ProjectFileModel> deserializeProjectFile(String path) async {
  final fileContents = await File(path).readAsString();

  var projectData = ProjectFileModel.fromJson(fileContents);

  // Coerce Metadata Properties.
  // Project Name
  if (projectData.metadata.projectName.isEmpty) {
    projectData = projectData.copyWith(
        metadata: projectData.metadata
            .copyWith(projectName: p.basenameWithoutExtension(path)));
  }

  return projectData;
}
