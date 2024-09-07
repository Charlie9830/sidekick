class FileState {
  final String fixtureImportPath;

  FileState({
    this.fixtureImportPath = "",
  });

  FileState.initial() : fixtureImportPath = "";

  FileState copyWith({
    String? fixtureImportPath,
  }) {
    return FileState(
      fixtureImportPath: fixtureImportPath ?? this.fixtureImportPath,
    );
  }
}
