import 'package:sidekick/redux/models/import_settings_model.dart';

class ImportViewModel {
  final String importFilePath;
  final ImportSettingsModel settings;
  final List<String> sheetNames;
  final void Function(ImportSettingsModel newSettings) onSettingsChanged;
  final void Function(String path) onFileSelected;
  final void Function() onImportButtonPressed;

  ImportViewModel({
    required this.importFilePath,
    required this.settings,
    required this.onSettingsChanged,
    required this.onFileSelected,
    required this.onImportButtonPressed,
    required this.sheetNames,
  });
}
