import 'package:excel/excel.dart';

List<Data?> extractHeaderRow(Sheet sheet) {
  return sheet.rows.first;
}
