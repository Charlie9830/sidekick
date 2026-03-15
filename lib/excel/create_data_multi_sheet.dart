import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

void createDataMultiSheet({
  required Excel excel,
  required Map<String, DataPatchModel> dataOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, CableModel> cables,
  required Map<String, LocationModel> locations,
  required Map<String, DataRackModel> dataRacks,
}) {
  final sheet = excel['Data Multis'];

  // Header Rows
  sheet.appendRow([
    TextCellValue('Rack Number'),
    TextCellValue('Multi ID'),
    TextCellValue('Multi Name'),
    TextCellValue('Line 1'),
    TextCellValue('Line 2'),
    TextCellValue('Line 3'),
    TextCellValue('Line 4'),
    TextCellValue('Color'),
  ]);

  final cablesByParentMultiId =
      cables.values.groupListsBy((cable) => cable.parentMultiId);

  for (final (rackIndex, rack) in dataRacks.values.indexed) {
    final associatedMultiOutlets = _extractAssociatedDataMultis(
      rackId: rack.uid,
      dataOutlets: dataOutlets,
      dataMultis: dataMultis,
      cables: cables,
    );

    for (final (multiIndex, multi) in associatedMultiOutlets.indexed) {
      final rootMultiCable = cables.values.firstWhereOrNull(
          (cable) => cable.upstreamId.isEmpty && cable.outletId == multi.uid);

      if (rootMultiCable == null) {
        continue;
      }

      final locationColor = locations[multi.locationId]?.color;
      final namedColor = locationColor != null
          ? locationColor.firstColorOrNone.name.toLowerCase()
          : '';

      final childOutlets = cablesByParentMultiId[rootMultiCable.uid]
              ?.map((cable) => dataOutlets[cable.outletId])
              .nonNulls
              .toList() ??
          [];

      sheet.appendRow([
        IntCellValue(rackIndex + 1),
        IntCellValue(multiIndex + 1),
        TextCellValue(multi.name),
        TextCellValue(childOutlets.elementAtOrNull(0)?.nameWithUniverse ?? ''),
        TextCellValue(childOutlets.elementAtOrNull(1)?.nameWithUniverse ?? ''),
        TextCellValue(childOutlets.elementAtOrNull(2)?.nameWithUniverse ?? ''),
        TextCellValue(childOutlets.elementAtOrNull(3)?.nameWithUniverse ?? ''),
        TextCellValue(namedColor.toLowerCase()),
      ]);
    }
  }
}

List<DataMultiModel> _extractAssociatedDataMultis({
  required String rackId,
  required Map<String, DataPatchModel> dataOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, CableModel> cables,
}) {
  final associatedPatchOutletIds = dataOutlets.values
      .where((outlet) => outlet.parentRack.rackId == rackId)
      .map((outlet) => outlet.uid)
      .toSet();

  final associatedCables = cables.values.where((cable) =>
      cable.upstreamId.isEmpty &&
      associatedPatchOutletIds.contains(cable.outletId));

  final associatedMultiCables = associatedCables
      .where((cable) =>
          cable.parentMultiId.isNotEmpty && cable.type == CableType.dmx)
      .map((cable) => cable.parentMultiId)
      .map((multiId) => cables[multiId])
      .nonNulls;

  final rootAssociatedMultiOutlets = associatedMultiCables
      .map((multiCable) => dataMultis[multiCable.outletId])
      .nonNulls
      .where((multi) => multi.isDetached == false);

  return rootAssociatedMultiOutlets.toModelMap().values.toList();
}
