import 'package:excel/excel.dart';
import 'package:sidekick/data_selectors/select_location_label.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/excel/sheet_indexer.dart';
import 'package:sidekick/excel/styles.dart';
import 'package:sidekick/excel/write_cable_rows.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void createPermanentLoomsSheet({
  required Excel excel,
  required Map<String, CableModel> cables,
  required Map<String, LoomModel> looms,
  required Map<String, LocationModel> locations,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
}) {
  final sheet = excel['Permanents'];

  final pointer = SheetIndexer();

  final loomsByLocation = locations.values.map((location) => (
        location,
        looms.values
            .where((loom) => loom.locationIds.contains(location.uid))
            .toList()
      ));

  for (final (location, loomsInLocation) in loomsByLocation) {
    final permanentLooms =
        loomsInLocation.where((loom) => loom.type.type == LoomType.permanent);
    for (final loom in permanentLooms) {
      ///
      ///  Header Row.
      ///

      // Loom Name
      sheet.setColumnWidth(pointer.columnIndex, 10);
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        TextCellValue(selectLoomName(loomsInLocation, location, loom)),
        cellStyle: loomHeaderStyle,
      );

      // 2nd Column
      sheet.setColumnWidth(pointer.columnIndex, 20);
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        null,
        cellStyle: loomHeaderStyle,
      );

      // 3rd Column
      sheet.setColumnWidth(pointer.columnIndex, 20);
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        null,
        cellStyle: loomHeaderStyle,
      );

      // Location
      sheet.setColumnWidth(pointer.columnIndex, 20);
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        TextCellValue(selectLocationLabel(
            locationIds: loom.locationIds, locations: locations)),
        cellStyle: loomHeaderStyle.copyWith(boldVal: false),
      );

      pointer.carriageReturn();

      ///
      /// Composition Row
      ///
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        TextCellValue(loom.type.permanentComposition),
        cellStyle: compositionRowStyle
            .copyWith(boldVal: false)
            .copyWith(leftBorderVal: Border(borderStyle: BorderStyle.Thick)),
      );

      // 2nd Column
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        null,
        cellStyle: compositionRowStyle.copyWith(boldVal: false),
      );

      // Color Title
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        TextCellValue('Color'),
        cellStyle: compositionRowStyle.copyWith(boldVal: false),
      );

      // Notes Title
      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
        TextCellValue('Notes'),
        cellStyle: compositionRowStyle.copyWith(
            boldVal: false,
            rightBorderVal: Border(borderStyle: BorderStyle.Thick)),
      );

      ///
      /// Cable Data Rows
      ///
      writeCableRows(
        loom: loom,
        cables: cables,
        dataMultis: dataMultis,
        dataPatches: dataPatches,
        locations: locations,
        pointer: pointer,
        powerMultiOutlets: powerMultiOutlets,
        sheet: sheet,
      );

      // Gap Between Looms.
      pointer.carriageReturn();
      pointer.carriageReturn();
    }
  }
}
