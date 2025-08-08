import 'package:excel/excel.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/excel/constants.dart';
import 'package:sidekick/excel/sheet_indexer.dart';

import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

void createHoistPatchSheet({
  required Excel excel,
  required Store<AppState> store,
}) {
  final sheet = excel['Motor patch'];

  final controllerVms = selectHoistControllers(
      store: store,
      selectedHoistChannelViewModelMap: {},
      cablesByHoistId: selectCablesByOutletId(store));

  SheetIndexer indexer = SheetIndexer(
      initial: CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
  for (final vm in controllerVms) {
    indexer =
        _writeHoistController(sheet: sheet, indexer: indexer, controllerVm: vm);
  }
}

SheetIndexer _writeHoistController(
    {required Sheet sheet,
    required SheetIndexer indexer,
    required HoistControllerViewModel controllerVm}) {
  // Styles.
  final headerBaseStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#595959"),
    fontFamily: 'Aptos',
    fontColorHex: ExcelColor.white,
    fontSize: 12,
  );
  final border = Border(borderStyle: BorderStyle.Thin);
  final nonInteractiveCellStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#D9D9D9"),
    fontFamily: 'Aptos Narrow',
    bold: true,
    fontSize: 11,
    bottomBorder: border,
    leftBorder: border,
    rightBorder: border,
    topBorder: border,
    horizontalAlign: HorizontalAlign.Center,
  );

  final columnHeaderStyle = CellStyle(
    fontFamily: 'Aptos Narrow',
    bold: true,
    fontSize: 11,
    bottomBorder: border,
    leftBorder: border,
    rightBorder: border,
    topBorder: border,
  );

  final valueCellStyle = CellStyle(
    fontFamily: 'Aptos Narrow',
    fontSize: 11,
    bottomBorder: border,
    leftBorder: border,
    rightBorder: border,
    topBorder: border,
  );

  // Contents
  final List<Row> contents = [
    // Header Row
    Row(children: [
      Cell(
        TextCellValue(controllerVm.controller.name),
        style: headerBaseStyle.copyWith(boldVal: true),
      ),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell(
        TextCellValue('${controllerVm.controller.ways}way'),
        style: headerBaseStyle.copyWith(
            boldVal: true, horizontalAlignVal: HorizontalAlign.Right),
      ),
    ]),

    // Subheading Row
    Row(children: [
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell.blank(style: headerBaseStyle),
      Cell(
        TextCellValue('Notes'),
        style: headerBaseStyle.copyWith(
            fontSizeVal: 11,
            horizontalAlignVal: HorizontalAlign.Right,
            fontFamilyVal: 'Aptos Narrow'),
      ),
    ]),

    // Column Header Row
    Row(children: [
      Cell(TextCellValue("Ch#"), style: nonInteractiveCellStyle, width: 8.11),
      Cell(TextCellValue("Hoist Name"), style: columnHeaderStyle, width: 16.22),
      Cell(TextCellValue("Location"), style: columnHeaderStyle, width: 18.22),
      Cell(TextCellValue("Multi"), style: columnHeaderStyle, width: 8.44),
      Cell(TextCellValue("Patch"), style: columnHeaderStyle, width: 8.11),
      Cell(TextCellValue("Notes"), style: columnHeaderStyle, width: 23.78),
    ]),

    // Contents Rows
    ...controllerVm.channels.map((channel) => Row(children: [
          Cell(
            IntCellValue(channel.number),
            style: nonInteractiveCellStyle,
          ),
          Cell(
            TextCellValue(channel.hoist?.hoist.name ?? ''),
            style: valueCellStyle,
          ),
          Cell(
            TextCellValue(channel.hoist?.locationName ?? ''),
            style: valueCellStyle,
          ),
          Cell(
            TextCellValue(channel.hoist?.multi ?? ''),
            style: valueCellStyle,
          ),
          Cell(
            TextCellValue(channel.hoist?.patch ?? ''),
            style: valueCellStyle,
          ),
          Cell(
            TextCellValue(channel.hoist?.hoist.controllerNote ?? ''),
            style: valueCellStyle,
          ),
        ]))
  ];

  for (final row in contents) {
    for (final cell in row.children) {
      if (cell.width != null) {
        sheet.setColumnWidth(
            indexer.current.columnIndex, cell.width! + kColumnWidthOffset);
      }

      sheet.updateCell(indexer.current, cell.value, cellStyle: cell.style);
      indexer.stepRight();
    }
    indexer.carriageReturn();
  }

  indexer.carriageReturn();
  return indexer;
}

class Row {
  final List<Cell> children;

  Row({this.children = const []});
}

class Cell {
  final CellValue? value;
  final CellStyle? style;
  final double? width;

  Cell(
    this.value, {
    this.style,
    this.width,
  });

  factory Cell.blank({CellStyle? style}) {
    return Cell(null, style: style);
  }
}
