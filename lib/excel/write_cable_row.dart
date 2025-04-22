import 'package:excel/excel.dart';
import 'package:sidekick/excel/sheet_indexer.dart';
import 'package:sidekick/excel/styles.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/view_models/cable_view_model.dart';

SheetIndexer writeCableRow({
  required Sheet sheet,
  required SheetIndexer pointer,
  required CableViewModel viewModel,
  required LoomModel parentLoom,
}) {
  // Length Cell
  sheet.updateCell(
      pointer.current,
      TextCellValue(
        viewModel.cable.parentMultiId.isEmpty
            ? switch (parentLoom.type.type) {
                LoomType.custom => '${viewModel.cable.humanFriendlyLength}m',
                LoomType.permanent => '-',
              }
            : '-',
      ),
      cellStyle: cableRowStyle.copyWith(
        horizontalAlignVal: HorizontalAlign.Left,
      ));

  pointer.stepRight();

  // Type and Local Number Cell
  sheet.updateCell(
    pointer.current,
    TextCellValue(
      viewModel.typeLabel,
    ),
    cellStyle: cableRowStyle,
  );

  pointer.stepRight();

  // Label Cell
  sheet.updateCell(
      pointer.current,
      TextCellValue(
        viewModel.label,
      ),
      cellStyle: cableRowStyle);

  pointer.stepRight();

  // Cable Flag Cell
  sheet.updateCell(
      pointer.current,
      TextCellValue(
        viewModel.isExtension
            ? 'Ext'
            : viewModel.cable.isSpare
                ? 'SP'
                : viewModel.cable.isDropper
                    ? 'Drop'
                    : '',
      ),
      cellStyle:
          cableRowStyle.copyWith(horizontalAlignVal: HorizontalAlign.Center));

  pointer.stepRight();

  // Label Color Cell.
  sheet.updateCell(
    pointer.current,
    TextCellValue(
      viewModel.labelColor.name,
    ),
    cellStyle: cableRowStyle,
  );

  pointer.stepRight();

  // Notes
  sheet.updateCell(
    pointer.current,
    TextCellValue(
      viewModel.cable.notes,
    ),
    cellStyle: cableRowStyle.copyWith(italicVal: true),
  );

  return pointer;
}
