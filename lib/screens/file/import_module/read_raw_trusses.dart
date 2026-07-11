import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/cable_graph/vector3.dart';
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
  final readResult = await mvrReader.read(parseGdtfFiles: false);

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
    trusses: trusses.map(_mapTruss).toList(),
    error: '',
  );
}

/// Maps a parsed [MVRTruss] into the app's [RawTrussModel].
///
/// The centroid comes from the truss's world bounding-box centre and the local
/// dimensions from its object-space box, both already in mm. The orientation is
/// taken as the (normalised) basis rows of the transform matrix, so any rake or
/// roll of the truss is preserved rather than collapsed to a Z rotation.
RawTrussModel _mapTruss(MVRTruss truss) {
  Vector3 axis(MVRVector3 v) => Vector3(v.x, v.y, v.z).normalized;

  return RawTrussModel(
    mvrId: truss.uuid,
    name: truss.name,
    classing: truss.classing,
    center: Vector3(truss.center.x, truss.center.y, truss.center.z),
    lengthAxis: axis(truss.matrix.xAxis),
    widthAxis: axis(truss.matrix.yAxis),
    heightAxis: axis(truss.matrix.zAxis),
    length: truss.objectBoundingBox.length,
    width: truss.objectBoundingBox.width,
    height: truss.objectBoundingBox.height,
  );
}

class ImportRawTrussesResult {
  final List<RawTrussModel> trusses;
  final String? error;

  ImportRawTrussesResult({required this.trusses, required this.error});
}
