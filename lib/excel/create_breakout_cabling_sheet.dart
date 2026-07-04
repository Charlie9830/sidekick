import 'package:excel_community/excel_community.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

/// Writes a per-location breakout cabling quantity matrix.
///
/// Locations are columns and each [CableQtyGroup] (type + length) is a row, with
/// the cell holding the quantity required. Cables broken at truss joins appear
/// as their shorter segments, matching the on-screen qty spreadsheet.
void createBreakoutCablingSheet({
  required Excel excel,
  required CableGraph cableGraph,
  required Map<String, LocationModel> locations,
}) {
  final sheet = excel['Breakout Cabling'];
  final qtysByLocation = selectCableQtysByLocationId(cableGraph);
  final locationList = locations.values.toList();
  final groups = CableQtyGroup.allGroups;

  sheet.appendRow([
    TextCellValue('Cable'),
    for (final location in locationList) TextCellValue(location.name),
  ]);

  for (final group in groups) {
    sheet.appendRow([
      TextCellValue(_formatCableGroup(group)),
      for (final location in locationList)
        _qtyCell(qtysByLocation[location.uid]?[group] ?? 0),
    ]);
  }
}

CellValue _qtyCell(int count) =>
    count == 0 ? TextCellValue('') : IntCellValue(count);

String _formatCableGroup(CableQtyGroup group) {
  final lengthText = group.length.remainder(1) == 0
      ? '${group.length.toStringAsFixed(0)}m'
      : '${group.length.toStringAsFixed(1)}m';

  final typeSlug = switch (group.type) {
    CableType.unknown => 'Unknown',
    CableType.socapex => 'Soca',
    CableType.wieland6way => '6way',
    CableType.sneak => 'Sneak',
    CableType.dmx => 'DMX',
    CableType.hoist => 'Motor Cable',
    CableType.hoistMulti => 'Motor Multi',
    CableType.au10a => '10A Ext',
    CableType.true1 => 'True1 Ext',
    CableType.socapexToAu10ALampHeader => 'Soca AU10A Header',
    CableType.socapexToTrue1LampHeader => 'Socapex True1 Header',
    CableType.wieland6WayLampHeader => '6way AU10A Header',
    CableType.sneakLampHeader => 'SS Lamp Header',
    CableType.hoistMultiLampHeader => 'Motor Multi Lamp Header',
    CableType.hoistMultiRackHeader => 'Motor Multi Rack Header',
  };

  const headerTypes = {
    CableType.socapexToAu10ALampHeader,
    CableType.socapexToTrue1LampHeader,
    CableType.sneakLampHeader,
    CableType.hoistMultiRackHeader,
    CableType.hoistMultiLampHeader,
    CableType.wieland6WayLampHeader,
  };

  return headerTypes.contains(group.type) ? typeSlug : '$lengthText $typeSlug';
}
