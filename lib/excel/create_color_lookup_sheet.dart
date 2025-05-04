import 'package:excel/excel.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createColorLookupSheet({
  required Excel excel,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, LocationModel> locations,
}) {
  final sheet = excel['Color Lookup'];

  // Header Rows
  sheet.appendRow([
    TextCellValue('Multicore Name'),
    TextCellValue('Color'),
  ]);

  for (final multi in powerMultis.values) {
    final location = locations[multi.locationId];
    final colorName = location == null
        ? ''
        : location.color.firstColorOrNone.name.toLowerCase();

    sheet.appendRow([
      TextCellValue(multi.name),
      TextCellValue(colorName),
    ]);
  }
}
