import 'package:sidekick/enums.dart';

class FileViewModel {

  final void Function(bool saveCurrentFile, String filePath)
      onOpenProjectButtonPressed;
  final void Function(SaveType saveType) onSaveProjectButtonPressed;
  final void Function(bool saveCurrentFile) onNewProjectButtonPressed;
  final String projectFilePath;

  FileViewModel({
    required this.onNewProjectButtonPressed,
    required this.onOpenProjectButtonPressed,
    required this.onSaveProjectButtonPressed,
    required this.projectFilePath,
  });
}
