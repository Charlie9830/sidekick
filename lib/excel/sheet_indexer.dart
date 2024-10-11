class SheetIndexer {
  int rowIndex = 0;
  int columnIndex = 0;

  SheetIndexer();

  int getColumnIndex() {
    return columnIndex++;
  }

  void carriageReturn() {
    columnIndex = 0;
    rowIndex++;
  }
}
