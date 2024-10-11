import 'package:excel/excel.dart';
import 'package:sidekick/data_selectors/select_location_label.dart';
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

void createCustomLoomsSheet({
  required Excel excel,
  required Map<String, CableModel> cables,
  required Map<String, LoomModel> looms,
  required Map<String, LocationModel> locations,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
}) {
  final sheet = excel['Customs'];

  final customLooms =
      looms.values.where((loom) => loom.type.type == LoomType.custom);

  final pointer = SheetIndexer();

  for (final loom in customLooms) {
    ///
    ///  Header Row.
    ///

    // Metadata Leading Row
    sheet.setColumnWidth(pointer.columnIndex, 2.5);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
      TextCellValue(">"),
      cellStyle: leadingCellStyle,
    );

    // Loom Name
    sheet.setColumnWidth(pointer.columnIndex, 8);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
      TextCellValue(loom.name),
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

    // 4th Column
    sheet.setColumnWidth(pointer.columnIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: pointer.getColumnIndex(), rowIndex: pointer.rowIndex),
      null,
      cellStyle: loomHeaderStyle,
    );

    // 5th Column
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
    
    ///
    /// Cable Data Rows
    ///
    writeCableRows(
        loom: loom,
        looms: looms,
        cables: cables,
        dataMultis: dataMultis,
        dataPatches: dataPatches,
        locations: locations,
        pointer: pointer,
        powerMultiOutlets: powerMultiOutlets,
        sheet: sheet,
        customRow: true);

    // Gap Between Looms.
    pointer.carriageReturn();
    pointer.carriageReturn();
  }
}
