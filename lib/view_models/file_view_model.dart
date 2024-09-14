import 'package:flutter/src/widgets/framework.dart';
import 'package:sidekick/enums.dart';

class FileViewModel {
  final void Function(String path) onFileSelected;
  final void Function(
          BuildContext context, bool saveCurrentFile, String filePath)
      onOpenProjectButtonPressed;
  final void Function(BuildContext context, SaveType saveType)
      onSaveProjectButtonPressed;
  final String importFilePath;

  final String projectFilePath;

  FileViewModel({
    required this.importFilePath,
    required this.onFileSelected,
    required this.onOpenProjectButtonPressed,
    required this.onSaveProjectButtonPressed,
    required this.projectFilePath,
  });
}
