class ImportViewModel {
  final String importFilePath;
  final void Function(String path) onFileSelected;
  final void Function() onImportManagerButtonPressed;

  ImportViewModel({
    required this.importFilePath,
    required this.onFileSelected,
    required this.onImportManagerButtonPressed,
  });
}
