import 'package:excel/excel.dart';
import 'package:sidekick/classes/numeric_span.dart';
import 'package:sidekick/excel/format_fixture_type.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

void createPowerPatchSheet(
    {required Excel excel,
    required Iterable<PowerOutletModel> outlets,
    required Map<String, PowerMultiOutletModel> powerMultis,
    required Map<String, LocationModel> locations,
    required Map<String, FixtureModel> fixtures,
    required Map<String, FixtureTypeModel> fixtureTypes}) {
  final powerPatchSheet = excel['Power Patch'];

  // Header Rows
  powerPatchSheet.appendRow([
    TextCellValue('Rack Number'),
    TextCellValue('Rack Outlet Number'),
    TextCellValue('Combined Rack Number and Outlet'),
    TextCellValue('Multi Name'),
    TextCellValue('Patch Outlet'),
    TextCellValue('Fixture Type'),
    TextCellValue('Fixture Number'),
    TextCellValue('Location'),
  ]);

  for (final (index, outlet) in outlets.indexed) {
    final rackNumber = ((index + 1) / 96).ceil();
    final outletNumber = (index % 96) + 1;

    final location = locations[outlet.locationId];
    final powerMultiOutlet = powerMultis[outlet.multiOutletId];

    powerPatchSheet.appendRow([
      // Rack Number
      IntCellValue(rackNumber),

      // Rack Outlet Number
      IntCellValue(outletNumber),

      // Combined Rack Number and Outlet Number
      TextCellValue('$rackNumber-$outletNumber'),

      // Multi name
      TextCellValue(powerMultiOutlet?.name ?? "UNNKOWN"),

      // Multi Patch
      IntCellValue(outlet.multiPatch),

      // Fixture Name
      TextCellValue(formatFixtureType(
          outlet.fixtureIds.map((id) => fixtures[id]!).toList(), fixtureTypes)),

      // Fixture ID
      TextCellValue(_formatFixtureNumbers(
          outlet.fixtureIds.map((id) => fixtures[id]!.fid))),

      // Location
      TextCellValue(location?.name ?? 'UNKNOWN')
    ]);
  }
}

String _formatFixtureNumbers(Iterable<int> fixtureIds) {
  if (fixtureIds.isEmpty) {
    return '';
  }

  if (fixtureIds.length == 1) {
    return fixtureIds.first.toString();
  }

  if (fixtureIds.length == 2) {
    return fixtureIds.join(', ');
  }

  final spans = NumericSpan.createSpans(fixtureIds.toList());

  return spans.map((span) => _formatNumericSpan(span)).join(', ');
}

String _formatNumericSpan(NumericSpan span) {
  return '${span.startsAt} - ${span.endsAt}';
}
