import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_type_label.dart';
import 'package:sidekick/excel/styles.dart';
import 'package:sidekick/data_selectors/select_title_case_color.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void writeCableLine(
  Sheet sheet,
  int Function() getColumnIndex,
  int rowIndex,
  CableModel cable,
  int index,
  CellStyle cableRowStyle,
  Map<String, PowerMultiOutletModel> powerMultiOutlets,
  Map<String, DataMultiModel> dataMultis,
  Map<String, DataPatchModel> dataPatches,
  Map<String, LocationModel> locations,
  bool customRow,
) {
  if (customRow) {
    // Leader.
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue("V"),
      cellStyle: leadingCellStyle,
    );

    // Length
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue('${cable.length.toStringAsFixed(0)}m'),
      cellStyle: cableRowStyle,
    );
  }

  // Cable Type
  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(
        '${selectCableTypeLabel(cable: cable, dataMultis: dataMultis, dataPatches: dataPatches, powerMultiOutlets: powerMultiOutlets)} ${index + 1}'),
    cellStyle: cableRowStyle,
  );

  // Label
  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(selectCableLabel(
      powerMultiOutlets: powerMultiOutlets,
      dataMultis: dataMultis,
      dataPatches: dataPatches,
      cable: cable,
      includeUniverse: true,
    )),
    cellStyle: cableRowStyle,
  );

  // Color
  final location = locations[cable.locationId];
  final color = location == null ? '' : NamedColors.names[location.color];

  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(selectTitleCaseColor(color ?? '')),
    cellStyle: cableRowStyle,
  );

  // Notes
  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(cable.notes),
    cellStyle: cableRowStyle,
  );
}
