import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/classes/numeric_span.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createColorLookupSheet({
  required Excel excel,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, LocationModel> locations,
}) {
  final sheet = excel['Color Lookup'];

  // Header Rows
  sheet.appendRow(const [
    TextCellValue('Multicore Name'),
    TextCellValue('Color'),
  ]);

  for (final multi in powerMultis.values) {
    final location = locations[multi.locationId];
    final colorName =
        location == null ? '' : NamedColors.names[location.color] ?? '';

    sheet.appendRow([
      TextCellValue(multi.name),
      TextCellValue(colorName),
    ]);
  }
}