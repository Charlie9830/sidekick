import 'package:excel/excel.dart';

String extractTextValue(Data? data) {
  return switch (data?.value) {
    null => '',
    TextCellValue v => v.value.text ?? '',
    DoubleCellValue v => v.value.toString(),
    IntCellValue v => v.value.toString(),
    _ => '',
  };
}
