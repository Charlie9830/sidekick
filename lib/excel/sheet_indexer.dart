import 'package:excel/excel.dart';

class SheetIndexer {
  CellIndex current;

  SheetIndexer({CellIndex? initial})
      : current =
            initial ?? CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);

  void stepRight() {
    current = CellIndex.indexByColumnRow(
        columnIndex: current.columnIndex + 1, rowIndex: current.rowIndex);
  }

  void stepDown() {
    current = CellIndex.indexByColumnRow(
      columnIndex: current.columnIndex,
      rowIndex: current.rowIndex + 1,
    );
  }

  void carriageReturn() {
    current = CellIndex.indexByColumnRow(
        columnIndex: 0, rowIndex: current.rowIndex + 1);
  }
}
