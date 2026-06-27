import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';

import 'package:sidekick/screens/file/import_module/raw_truss_model.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';

Future<ImportRawTrussesResult> readRawTrusses({
  required PatchImportSettings settings,
  required String patchFilePath,
}) async {
  return switch (settings.source) {
    PatchSource.grandMA2XML => ImportRawTrussesResult(trusses: [], error: null),
    PatchSource.mvr => await _readMvrTrussing(
      patchFilePath: patchFilePath,
      settings: settings,
    ),
  };
}

Future<ImportRawTrussesResult> _readMvrTrussing({
  required String patchFilePath,
  required PatchImportSettings settings,
}) async {
  final mvrReader = MVR(filePath: patchFilePath);
  final readResult = await mvrReader.read(expandGdtfFiles: false);

  if (readResult == false) {
    return ImportRawTrussesResult(
      trusses: [],
      error: 'An unknown error occured reading the MVR File ',
    );
  }

  final trusses = mvrReader.generalSceneDescription.layers
      .map((layer) {
        return layer.children.whereType<MVRTruss>();
      })
      .flattened
      .toList();

  return ImportRawTrussesResult(
    trusses: trusses
        .map(
          (truss) => RawTrussModel(
            mvrId: truss.uuid,
            rotationX: truss.matrix.rotationX,
            rotationY: truss.matrix.rotationY,
            rotationZ: truss.matrix.rotationZ,
            length: truss.length,
            width: truss.width,
            height: truss.height,
            x: truss.matrix.x,
            y: truss.matrix.y,
            z: truss.matrix.z,
          ),
        )
        .toList(),
    error: '',
  );
}

class ImportRawTrussesResult {
  final List<RawTrussModel> trusses;
  final String? error;

  ImportRawTrussesResult({required this.trusses, required this.error});
}
