import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
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

  final cablesByParentMultiId =
      cables.values.groupListsBy((cable) => cable.parentMultiId);

  const Set<String> kSneakPanelPrimaryColorOrder = {
    'Red',
    'White',
    'Blue',
    'Orange',
    'Yellow',
    'Green',
    'Purple',
    'Brown',
  };

  final dataMultiQueuesByColor = dataMultis.values.groupListsBy((multi) {
    final colorName = locations[multi.locationId]?.color.name;
    if (colorName == null ||
        kSneakPanelPrimaryColorOrder.contains(colorName) == false) {
      return '';
    }

    return colorName;
  }).map((key, value) => MapEntry(key, Queue<DataMultiModel>.from(value)));

  final multisOrderedBySneakPanelColour = [
    ...kSneakPanelPrimaryColorOrder.map((colorName) {
      final queue = dataMultiQueuesByColor[colorName];

      if (queue != null && queue.isNotEmpty) {
        return queue.removeFirst();
      }
    }).nonNulls,
    ...dataMultiQueuesByColor.entries
        .map((entry) => entry.value.toList())
        .flattened,
  ];

  assert(multisOrderedBySneakPanelColour.length == dataMultis.values.length,
      'Ordering of Data Multis resulted in a different quantity');

  for (final (index, multi) in dataMultis.values.indexed) {
    final locationColor = locations[multi.locationId]?.color;

    final namedColor =
        locationColor != null ? NamedColors.names[locationColor] ?? '' : '';

    final associatedSneak =
        cables.values.firstWhereOrNull((cable) => cable.outletId == multi.uid);

    final childPatches = associatedSneak != null
        ? cablesByParentMultiId[associatedSneak.uid]
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
