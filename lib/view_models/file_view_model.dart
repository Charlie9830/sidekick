import 'package:sidekick/enums.dart';

class FileViewModel {
  final void Function(bool saveCurrentFile, String filePath)
      onOpenProjectButtonPressed;
  final void Function(SaveType saveType) onSaveProjectButtonPressed;
  final void Function(bool saveCurrentFile) onNewProjectButtonPressed;
  final void Function(String path) onFixtureTypeDatabaseFileSelected;
  final String projectFilePath;
  final String fixtureTypeDatabasePath;
  final bool isFixtureTypeDatabasePathValid;

  FileViewModel({
    required this.onNewProjectButtonPressed,
    required this.onOpenProjectButtonPressed,
    required this.onSaveProjectButtonPressed,
    required this.projectFilePath,
    required this.fixtureTypeDatabasePath,
    required this.onFixtureTypeDatabaseFileSelected,
    required this.isFixtureTypeDatabasePathValid,
  });
}
