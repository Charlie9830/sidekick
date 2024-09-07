class FileViewModel {
  final void Function(String path) onFileSelected;
  final String importFilePath;

  FileViewModel({
    required this.importFilePath,
    required this.onFileSelected,
  });
}
