import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

void createDataMultiSheet({
  required Excel excel,
  required Iterable<DataPatchModel> dataOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, LocationModel> locations,
}) {
  final sheet = excel['Data Multis'];

  // Header Rows
  sheet.appendRow(const [
    TextCellValue('Multi ID'),
    TextCellValue('Multi Name'),
    TextCellValue('Line 1'),
    TextCellValue('Line 2'),
    TextCellValue('Line 3'),
    TextCellValue('Line 4'),
    TextCellValue('Color'),
  ]);

  for (final (index, multi) in dataMultis.values.indexed) {
    final locationColor = locations[multi.locationId]?.color;

    final namedColor =
        locationColor != null ? NamedColors.names[locationColor] ?? '' : '';

    sheet.appendRow([
      IntCellValue(index + 1),
      TextCellValue(multi.name),
      for (final childPatch
          in dataOutlets.where((outlet) => outlet.multiId == multi.uid))
        TextCellValue(childPatch.nameWithUniverse),
      TextCellValue(namedColor),
    ]);
  }
}
