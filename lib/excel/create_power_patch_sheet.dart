import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/numeric_span.dart';
import 'package:sidekick/excel/format_fixture_type.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createPowerPatchSheet(
    {required Excel excel,
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

  final powerMultisByLocation =
      powerMultis.values.groupListsBy((multi) => multi.locationId);

  final orderedPowerMultis = locations.values
      .where((location) => location.isHybrid == false)
      .where((location) => location.isRiggingOnlyLocation == false)
      .map((location) =>
          powerMultisByLocation[location.uid] ??
          <PowerMultiOutletModel>[].sorted((a, b) => a.number - b.number))
      .flattened
      .toList();

  for (final (multiIndex, multi) in orderedPowerMultis.indexed) {
    final location = locations[multi.locationId]!;
    final rackNumber = ((multiIndex + 1) / 16).ceil();

    for (final outlet in multi.children) {
      int rackScopedOutletNumber = ((multiIndex * 6) + outlet.multiPatch) % 96;
      rackScopedOutletNumber == 0
          ? rackScopedOutletNumber = 96
          : rackScopedOutletNumber;

      powerPatchSheet.appendRow([
        // Rack Number
        IntCellValue(rackNumber),

        // Rack Outlet Number
        IntCellValue(rackScopedOutletNumber),

        // Combined Rack Number and Outlet Number
        TextCellValue('$rackNumber-$rackScopedOutletNumber'),

        // Multi name
        TextCellValue(multi.name),

        // Multi Patch
        IntCellValue(outlet.multiPatch),

        // Fixture Name
        TextCellValue(formatFixtureType(
            outlet.fixtureIds.map((id) => fixtures[id]!).toList(),
            fixtureTypes)),

        // Fixture ID
        TextCellValue(_formatFixtureNumbers(
            outlet.fixtureIds.map((id) => fixtures[id]!.fid))),

        // Location
        TextCellValue(location.name)
      ]);
    }
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
