import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/data_rack_type_model.dart';

import '../redux/models/location_model.dart';

void createDataPatchSheet({
  required Excel excel,
  required Iterable<DataPatchModel> dataOutlets,
  required Map<String, LocationModel> locations,
  required Map<String, CableModel> cables,
  required Map<String, DataRackModel> dataRacks,
  required Map<String, DataRackTypeModel> dataRackTypes,
}) {
  final sheet = excel['Data Patch'];

  // Header Rows
  sheet.appendRow([
    TextCellValue('Rack Number'),
    TextCellValue('Outlet ID'),
    TextCellValue('Universe'),
    TextCellValue('Cable'),
    TextCellValue('Type'),
    TextCellValue('Color'),
  ]);

  for (final (rackIndex, rack) in dataRacks.values.indexed) {
    final totalOutletCount = dataRackTypes[rack.typeId]!.outletCount;

    final activePatches = _extractActivePatches(cables, dataOutlets, rack.uid);
    final activePatchesByChannel = Map<int, DataPatchModel>.fromEntries(
        activePatches
            .map((patch) => MapEntry(patch.parentRack.channel, patch)));
    final cablesByOutletId =
        cables.map((key, value) => MapEntry(value.outletId, value));

    for (int index = 0; index < totalOutletCount; index++) {
      final channel = index + 1;
      final nodeNumber = rackIndex + 1;
      final patch = activePatchesByChannel[channel];
      final portIdentifier = 'NODE$nodeNumber-PORT$channel';

      final locationColor = locations[patch?.locationId]?.color;

      final namedColor = locationColor != null
          ? locationColor.firstColorOrNone.name.toLowerCase()
          : '';

      // Lookup Sneak Parent if any.
      final associatedCable = cablesByOutletId[patch?.uid];
      final associatedSneak = cables[associatedCable?.parentMultiId];

      sheet.appendRow([
        IntCellValue(nodeNumber),
        TextCellValue(portIdentifier),
        IntCellValue(patch?.universe ?? 0),
        TextCellValue(patch?.name ?? ''),
        TextCellValue(patch == null
            ? ''
            : associatedSneak != null
                ? 'Sneak'
                : 'Single'),
        TextCellValue(namedColor),
      ]);
    }
  }
}

List<DataPatchModel> _extractActivePatches(Map<String, CableModel> cables,
    Iterable<DataPatchModel> allDataOutlets, String dataRackId) {
  return allDataOutlets
      .where((outlet) => outlet.parentRack.rackId == dataRackId)
      .toList();
}
