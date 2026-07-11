import 'package:excel_community/excel_community.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
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
      TextCellValue(group.label),
      for (final location in locationList)
        _qtyCell(qtysByLocation[location.uid]?[group] ?? 0),
    ]);
  }
}

CellValue _qtyCell(int count) =>
    count == 0 ? TextCellValue('') : IntCellValue(count);
