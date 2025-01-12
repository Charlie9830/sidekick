import 'package:excel/excel.dart';

List<List<Data?>> extractDataRows(Sheet sheet, int dataOffset) {
  return sheet.rows.sublist(dataOffset);
}
