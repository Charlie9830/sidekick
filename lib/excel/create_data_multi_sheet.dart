import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
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

  final Map<String, DataMultiModel?> assignedSneakPanelSlots = {
    'Red': null,
    'White': null,
    'Blue': null,
    'Orange': null,
    'Yellow': null,
    'Green': null,
    'Purple': null,
    'Brown': null,
    'Red/Grey': null,
    'White/Grey': null,
    'Blue/Grey': null,
    'Orange/Grey': null,
    'Yellow/Grey': null,
    'Green/Grey': null,
    'Purple/Grey': null,
    'Brown/Grey': null,
  };

  // Try to Assign Multis to their slots on the Sneak panel by Color in a first pass best effort manner. We will iterate once more
  // after this to ensure all remaining multis get assigned somewhere.
  final List<DataMultiModel> rejects = [];
  for (final multi in dataMultis.values) {
    final colorName = locations[multi.locationId]?.color.name;

    // Could'nt get a Suitable color. Send to the Reject Pile.
    if (colorName == null || colorName == const LabelColorModel.none().name) {
      rejects.add(multi);
      continue;
    }

    // Assign based on exact color if available.
    if (assignedSneakPanelSlots.containsKey(colorName) &&
        assignedSneakPanelSlots[colorName] == null) {
      assignedSneakPanelSlots[colorName] = multi;
      continue;
    }

    // Assign based on Secondary (Greyed) color if available.
    if (assignedSneakPanelSlots.containsKey('$colorName/Grey') &&
        assignedSneakPanelSlots[colorName] == null) {
      assignedSneakPanelSlots['$colorName/Grey'] = multi;
      continue;
    }

    // Nothing available. Send to the Reject Pile for now.
    rejects.add(multi);
  }

  // Now assign the rejects to any leftover slots. Only creating more once we have completly filled all available slots.
  for (final rejectedMulti in rejects) {
    final nextAvailableSlotKey = assignedSneakPanelSlots.entries
        .firstWhereOrNull((entry) => entry.value == null)
        ?.key;

    if (nextAvailableSlotKey != null) {
      assignedSneakPanelSlots[nextAvailableSlotKey] = rejectedMulti;
      continue;
    }

    assignedSneakPanelSlots[rejectedMulti.uid] = rejectedMulti;
  }

  for (final (index, multi) in assignedSneakPanelSlots.values.indexed) {
    if (multi == null) {
      // Append an Empty Row.
      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      continue;
    }

    final locationColor = locations[multi.locationId]?.color;

    final namedColor = locationColor != null ? locationColor.name : '';

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

class SneakPanelSlot {
  final String colorName;
  final DataMultiModel multi;

  SneakPanelSlot({
    required this.colorName,
    required this.multi,
  });
}
