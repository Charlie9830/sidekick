import 'package:excel/excel.dart';

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

final leadingCellStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString("#404040"),
  fontColorHex: ExcelColor.fromHexString("#404040"),
);