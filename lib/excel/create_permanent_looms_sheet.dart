import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
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

  final permanentLooms =
      looms.values.where((loom) => loom.type.type == LoomType.permanent);

  final loomHeaderStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#404040"),
    fontColorHex: ExcelColor.white,
    bold: true,
    fontFamily: 'Verdana',
  );

  final compositionRowStyle = CellStyle(
    fontFamily: 'Verdana',
    bold: true,
    bottomBorder: Border(borderStyle: BorderStyle.Thick),
  );

  final cableRowStyle = CellStyle(
    fontFamily: 'Verdana',
    bottomBorder: Border(borderStyle: BorderStyle.Medium),
    topBorder: Border(borderStyle: BorderStyle.Medium),
    leftBorder: Border(borderStyle: BorderStyle.Medium),
    rightBorder: Border(borderStyle: BorderStyle.Medium),
  );

  int rowIndex = 0;
  for (final loom in permanentLooms) {
    int columnIndex = 0;
    int getColumnIndex() => columnIndex++;
    void carriageReturn() {
      columnIndex = 0;
      rowIndex++;
    }

    // Header Row.
    sheet.setColumnWidth(rowIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(loom.name),
      cellStyle: loomHeaderStyle,
    );

    sheet.setColumnWidth(rowIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(''),
      cellStyle: loomHeaderStyle,
    );

    sheet.setColumnWidth(rowIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(''),
      cellStyle: loomHeaderStyle,
    );

    sheet.setColumnWidth(rowIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(''),
      cellStyle: loomHeaderStyle.copyWith(boldVal: false),
    );

    carriageReturn();

    // Composition Row
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(loom.type.permanentComposition),
      cellStyle: compositionRowStyle
          .copyWith(boldVal: false)
          .copyWith(leftBorderVal: Border(borderStyle: BorderStyle.Thick)),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(''),
      cellStyle: compositionRowStyle.copyWith(boldVal: false),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue('Color'),
      cellStyle: compositionRowStyle.copyWith(boldVal: false),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue('Notes'),
      cellStyle: compositionRowStyle.copyWith(
          boldVal: false,
          rightBorderVal: Border(borderStyle: BorderStyle.Thick)),
    );

    // Cable Rows
    final associatedCables =
        loom.childrenIds.map((id) => cables[id]).nonNulls.toList();
    for (final cable in associatedCables) {
      carriageReturn();

      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: getColumnIndex(), rowIndex: rowIndex),
        TextCellValue(cable.type.name),
        cellStyle: cableRowStyle,
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: getColumnIndex(), rowIndex: rowIndex),
        TextCellValue(selectCableLabel(
            powerMultiOutlets: powerMultiOutlets,
            dataMultis: dataMultis,
            dataPatches: dataPatches,
            cable: cable)),
        cellStyle: cableRowStyle,
      );

      final location = locations[cable.locationId];
      final color = location == null ? '' : NamedColors.names[location.color];

      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: getColumnIndex(), rowIndex: rowIndex),
        TextCellValue(color ?? ''),
        cellStyle: cableRowStyle,
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
            columnIndex: getColumnIndex(), rowIndex: rowIndex),
        TextCellValue(cable.notes),
        cellStyle: cableRowStyle,
      );
    }

    carriageReturn();
    carriageReturn();
  }
}
