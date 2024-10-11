import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_type_label.dart';
import 'package:sidekick/data_selectors/select_location_label.dart';
import 'package:sidekick/excel/title_case_color.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

const List<CableType> _typeOrdering = [
  CableType.socapex,
  CableType.wieland6way,
  CableType.sneak,
  CableType.dmx,
];

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

    ///
    ///  Header Row.
    ///

    // Loom Name
    sheet.setColumnWidth(columnIndex, 10);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(loom.name),
      cellStyle: loomHeaderStyle,
    );

    // 2nd Column
    sheet.setColumnWidth(columnIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      null,
      cellStyle: loomHeaderStyle,
    );

    // 3rd Column
    sheet.setColumnWidth(columnIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      null,
      cellStyle: loomHeaderStyle,
    );

    // Location
    sheet.setColumnWidth(columnIndex, 20);
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(selectLocationLabel(
          locationIds: loom.locationIds, locations: locations)),
      cellStyle: loomHeaderStyle.copyWith(boldVal: false),
    );

    carriageReturn();

    ///
    /// Composition Row
    ///
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue(loom.type.permanentComposition),
      cellStyle: compositionRowStyle
          .copyWith(boldVal: false)
          .copyWith(leftBorderVal: Border(borderStyle: BorderStyle.Thick)),
    );
    
    
    // 2nd Column 
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      null,
      cellStyle: compositionRowStyle.copyWith(boldVal: false),
    );


    // Color Title
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue('Color'),
      cellStyle: compositionRowStyle.copyWith(boldVal: false),
    );

    // Notes Title
    sheet.updateCell(
      CellIndex.indexByColumnRow(
          columnIndex: getColumnIndex(), rowIndex: rowIndex),
      TextCellValue('Notes'),
      cellStyle: compositionRowStyle.copyWith(
          boldVal: false,
          rightBorderVal: Border(borderStyle: BorderStyle.Thick)),
    );

    ///
    /// Cable Data Rows
    /// 
    final associatedCables =
        loom.childrenIds.map((id) => cables[id]).nonNulls.toList();

    final cablesByType =
        associatedCables.groupListsBy((element) => element.type);

    final cablesSortedByType =
        _typeOrdering.map((type) => cablesByType[type] ?? []);

    for (final cableList in cablesSortedByType) {
      for (final (index, cable) in cableList.indexed) {
        carriageReturn();
        _writeCableLine(
          sheet,
          getColumnIndex,
          rowIndex,
          cable,
          index,
          cableRowStyle,
          powerMultiOutlets,
          dataMultis,
          dataPatches,
          locations,
        );

        if (cable.type == CableType.sneak) {
          // We need to write the children of the sneak.
          final children = dataPatches.values
              .where((patch) => patch.multiId == cable.outletId);

          final childrenAsCables = children.map((child) => CableModel(
                type: CableType.dmx,
                uid: '',
                locationId: child.locationId,
                outletId: child.uid,
                upstreamId: '',
              ));

          for (final (sneakIndex, sneakPatch) in childrenAsCables.indexed) {
            carriageReturn();
            _writeCableLine(
              sheet,
              getColumnIndex,
              rowIndex,
              sneakPatch,
              sneakIndex,
              cableRowStyle,
              powerMultiOutlets,
              dataMultis,
              dataPatches,
              locations,
            );
          }
        }
      }
    }

    // Gap Between Looms.
    carriageReturn();
    carriageReturn();
  }
}

void _writeCableLine(
    Sheet sheet,
    int Function() getColumnIndex,
    int rowIndex,
    CableModel cable,
    int index,
    CellStyle cableRowStyle,
    Map<String, PowerMultiOutletModel> powerMultiOutlets,
    Map<String, DataMultiModel> dataMultis,
    Map<String, DataPatchModel> dataPatches,
    Map<String, LocationModel> locations) {
  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(
        '${selectCableTypeLabel(cable: cable, dataMultis: dataMultis, dataPatches: dataPatches, powerMultiOutlets: powerMultiOutlets)} ${index + 1}'),
    cellStyle: cableRowStyle,
  );

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

  final location = locations[cable.locationId];
  final color = location == null ? '' : NamedColors.names[location.color];

  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(titleCaseColor(color ?? '')),
    cellStyle: cableRowStyle,
  );

  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: getColumnIndex(), rowIndex: rowIndex),
    TextCellValue(cable.notes),
    cellStyle: cableRowStyle,
  );
}
