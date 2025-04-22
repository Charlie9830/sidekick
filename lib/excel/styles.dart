import 'package:excel/excel.dart';

final loomHeaderStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString("#595959"),
  fontColorHex: ExcelColor.white,
  bold: true,
  fontFamily: 'Aptos',
  fontSize: 12,
);

final loomSubHeaderStyle = CellStyle(
  fontFamily: 'Aptos Narrow',
  bold: true,
  bottomBorder: Border(borderStyle: BorderStyle.Thick),
  fontSize: 11,
);

final cableRowStyle = CellStyle(
  fontFamily: 'Aptos Narrow',
  fontSize: 10,
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  topBorder: Border(borderStyle: BorderStyle.Thin),
  leftBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

final leadingCellStyle = CellStyle(
  fontFamily: 'Aptos Narrow',
  fontSize: 10,
  backgroundColorHex: ExcelColor.fromHexString("#404040"),
  fontColorHex: ExcelColor.fromHexString("#404040"),
);
