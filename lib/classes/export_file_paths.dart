import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanitize_filename/sanitize_filename.dart';

// This file name needs to hardcoded into the Template Excel documents in the parameters table because of Trash Power Query Relative file support.
const String _kReferenceFileName = 'phase_reference_data';

class ExportFilePaths {
  final String directoryPath;
  final String safeProjectName;
  final String excelFileExtension;

  ExportFilePaths({
    required this.directoryPath,
    required String projectName,
    required this.excelFileExtension,
  }) : safeProjectName = sanitizeFilename(projectName);

  String get referenceDataPath =>
      '${p.join(directoryPath, _kReferenceFileName)}$excelFileExtension';

  String get powerPatchPath =>
      '${p.join(directoryPath, _appendSlug('Power_Patch'))}$excelFileExtension';

  String get dataPatchPath =>
      '${p.join(directoryPath, _appendSlug('Data_Patch'))}$excelFileExtension';

  String get loomsPath =>
      '${p.join(directoryPath, _appendSlug('Looms'))}$excelFileExtension';

  String get addressesPath =>
      '${p.join(directoryPath, _appendSlug('DMX_Addressing'))}$excelFileExtension';

  String get fixtureInfoPath =>
      '${p.join(directoryPath, _appendSlug('Fixture_Info'))}$excelFileExtension';

  String get hoistPatchPath =>
      '${p.join(directoryPath, _appendSlug('Motor_Patch'))}$excelFileExtension';

  Future<bool> get parentDirectoryExists => Directory(directoryPath).exists();

  Future<List<String>> getAlreadyExistingFileNames() async {
    // A Delegate function that checks if a File exists. If it does exist, returns an empty string, otherwise returns the file basename.
    Future<String> checkExistsDelegate(String path) async =>
        await File(path).exists() ? p.basename(path) : '';

    final delegates = [
      checkExistsDelegate(referenceDataPath),
      checkExistsDelegate(powerPatchPath),
      checkExistsDelegate(dataPatchPath),
      checkExistsDelegate(loomsPath),
      checkExistsDelegate(addressesPath),
      checkExistsDelegate(fixtureInfoPath),
      checkExistsDelegate(hoistPatchPath),
    ];

    final existingFileNames = await Future.wait(delegates);

    return existingFileNames.where((name) => name.isNotEmpty).toList();
  }

  String _appendSlug(String slug) {
    return '$safeProjectName-$slug';
  }
}
