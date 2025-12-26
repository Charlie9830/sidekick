class ImportViewModel {
  final String importFilePath;
  final void Function() onImportManagerButtonPressed;

  ImportViewModel({
    required this.importFilePath,
    required this.onImportManagerButtonPressed,
  });
}
