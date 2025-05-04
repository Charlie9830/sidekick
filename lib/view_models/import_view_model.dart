import 'package:sidekick/redux/models/import_settings_model.dart';

class ImportViewModel {
  final String importFilePath;
  final List<String> sheetNames;
  final void Function(String path) onFileSelected;
  final void Function() onImportButtonPressed;
  final void Function() onImportManagerButtonPressed;

  ImportViewModel({
    required this.importFilePath,
    required this.onFileSelected,
    required this.onImportButtonPressed,
    required this.sheetNames,
    required this.onImportManagerButtonPressed,
  });
}
