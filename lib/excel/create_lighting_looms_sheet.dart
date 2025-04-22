import 'package:excel/excel.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/excel/constants.dart';
import 'package:sidekick/excel/sheet_indexer.dart';
import 'package:sidekick/excel/styles.dart';
import 'package:sidekick/excel/write_cable_row.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/state/app_state.dart';

void createLightingLoomsSheet({
  required Excel excel,
  required Store<AppState> store,
}) {
  final loomVms = selectLoomViewModels(store, forExcel: true);

  final sheet = excel['Lighting Looms'];
  final pointer = SheetIndexer();

  excel.setDefaultSheet('Lighting Looms');

  for (final loomVm in loomVms) {
    ///
    ///  Header Row.
    ///
    // Loom Name
    // 1st Column
    sheet.setColumnWidth(
        pointer.current.columnIndex, 6.56 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      TextCellValue(loomVm.name),
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 2nd Column
    sheet.setColumnWidth(pointer.current.columnIndex, 13 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 3rd Column
    sheet.setColumnWidth(
        pointer.current.columnIndex, 13.67 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 4th Column
    sheet.setColumnWidth(
        pointer.current.columnIndex, 5.44 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 5th Column
    sheet.setColumnWidth(
        pointer.current.columnIndex, 8.11 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 6th Column
    sheet.setColumnWidth(
        pointer.current.columnIndex, 33.44 + kColumnWidthOffset);
    sheet.updateCell(
      pointer.current,
      TextCellValue(switch (loomVm.loom.type.type) {
        LoomType.custom => "Custom",
        LoomType.permanent => "Permanent"
      }),
      cellStyle: loomHeaderStyle.copyWith(
        horizontalAlignVal: HorizontalAlign.Right,
        boldVal: true,
      ),
    );

    ///
    /// Subheading Row
    ///

    pointer.carriageReturn();

    // 1st Column
    sheet.updateCell(pointer.current,
        TextCellValue('${loomVm.loom.type.humanFriendlyLength}m'),
        cellStyle: loomHeaderStyle);

    pointer.stepRight();

    // 2nd Column
    sheet.updateCell(
        pointer.current,
        TextCellValue(loomVm.loom.type.type == LoomType.permanent
            ? loomVm.loom.type.permanentComposition
            : 'Custom'),
        cellStyle: loomHeaderStyle);

    pointer.stepRight();

    // 3rd Column
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 4th Column
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 5th Column
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    pointer.stepRight();

    // 6th Column
    sheet.updateCell(
      pointer.current,
      null,
      cellStyle: loomHeaderStyle,
    );

    ///
    /// Cable Rows
    ///

    pointer.carriageReturn();

    for (final cableVm in loomVm.children) {
      writeCableRow(
          sheet: sheet,
          pointer: pointer,
          viewModel: cableVm,
          parentLoom: loomVm.loom);

      if (cableVm != loomVm.children.last) {
        pointer.carriageReturn();
      }
    }

    // Gap Between Looms.
    pointer.carriageReturn();
    pointer.carriageReturn();
  }
}
