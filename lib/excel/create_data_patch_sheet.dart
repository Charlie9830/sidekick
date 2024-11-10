import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';

import '../redux/models/location_model.dart';

void createDataPatchSheet({
  required Excel excel,
  required Iterable<DataPatchModel> dataOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, LocationModel> locations,
  required Map<String, CableModel> cables,
}) {
  final sheet = excel['Data Patch'];

  // Header Rows
  sheet.appendRow([
    TextCellValue('Outlet ID'),
    TextCellValue('Universe'),
    TextCellValue('Cable'),
    TextCellValue('Type'),
    TextCellValue('Color'),
  ]);

  final activePatches = dataOutlets.where((outlet) => outlet.isSpare == false);

  final cablesByOutletId =
      cables.map((key, value) => MapEntry(value.outletId, value));

  for (final (index, patch) in activePatches.indexed) {
    final patchNumber = index + 1;
    final nodeNumber = (patchNumber / 8).ceil();

    final locationColor = locations[patch.locationId]?.color;

    final namedColor =
        locationColor != null ? NamedColors.names[locationColor] ?? '' : '';

    // Lookup Sneak Parent if any.
    final associatedCable = cablesByOutletId[patch.uid];
    final associatedSneak = cables[associatedCable?.parentMultiId];

    sheet.appendRow([
      TextCellValue(
          'NODE$nodeNumber-PORT${patchNumber % 8 == 0 ? 8 : patchNumber % 8}'),
      IntCellValue(patch.universe),
      TextCellValue(patch.name),
      TextCellValue(associatedSneak != null ? 'Sneak' : 'Single'),
      TextCellValue(namedColor),
    ]);
  }
}
