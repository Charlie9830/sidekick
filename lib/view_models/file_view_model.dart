import 'package:flutter/src/widgets/framework.dart';
import 'package:sidekick/enums.dart';

class FileViewModel {
  final void Function(String path) onFileSelected;
  final void Function(bool saveCurrentFile, String filePath)
      onOpenProjectButtonPressed;
  final void Function(SaveType saveType) onSaveProjectButtonPressed;
  final void Function(bool saveCurrentFile) onNewProjectButtonPressed;
  final String importFilePath;

  final String projectFilePath;

  FileViewModel({
    required this.onNewProjectButtonPressed,
    required this.importFilePath,
    required this.onFileSelected,
    required this.onOpenProjectButtonPressed,
    required this.onSaveProjectButtonPressed,
    required this.projectFilePath,
  });
}
