import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

void createDataMultiSheet({
  required Excel excel,
  required Map<String, DataPatchModel> dataOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, CableModel> cables,
  required Map<String, LocationModel> locations,
}) {
  final sheet = excel['Data Multis'];

  // Header Rows
  sheet.appendRow([
    TextCellValue('Multi ID'),
    TextCellValue('Multi Name'),
    TextCellValue('Line 1'),
    TextCellValue('Line 2'),
    TextCellValue('Line 3'),
    TextCellValue('Line 4'),
    TextCellValue('Color'),
  ]);

  final cablesByMultiId =
      cables.values.groupListsBy((cable) => cable.dataMultiId);

  for (final (index, multi) in dataMultis.values.indexed) {
    final locationColor = locations[multi.locationId]?.color;

    final namedColor =
        locationColor != null ? NamedColors.names[locationColor] ?? '' : '';

    final associatedSneak =
        cables.values.firstWhereOrNull((cable) => cable.outletId == multi.uid);

    final childPatches = associatedSneak != null
        ? cablesByMultiId[associatedSneak.uid]
                ?.map((cable) => dataOutlets[cable.outletId])
                .nonNulls
                .toList() ??
            <DataPatchModel>[]
        : <DataPatchModel>[];

    sheet.appendRow([
      IntCellValue(index + 1),
      TextCellValue(multi.name),
      
      TextCellValue(childPatches.elementAtOrNull(0)?.nameWithUniverse ?? ''),
      TextCellValue(childPatches.elementAtOrNull(1)?.nameWithUniverse ?? ''),
      TextCellValue(childPatches.elementAtOrNull(2)?.nameWithUniverse ?? ''),
      TextCellValue(childPatches.elementAtOrNull(3)?.nameWithUniverse ?? ''),

      TextCellValue(namedColor),
    ]);
  }
}
