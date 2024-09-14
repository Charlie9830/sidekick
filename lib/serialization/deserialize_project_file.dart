import 'dart:io';

import 'package:sidekick/serialization/project_file_model.dart';

Future<ProjectFileModel> deserializeProjectFile(String path) async {
  final fileContents = await File(path).readAsString();

  return ProjectFileModel.fromJson(fileContents);
}
