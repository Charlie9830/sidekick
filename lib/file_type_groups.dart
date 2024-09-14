import 'package:file_selector/file_selector.dart';

const kExcelFileTypes = <XTypeGroup>[
  XTypeGroup(
    label: "Excel Files (*.xls, *.xlsx)",
    extensions: ['xls', 'xlsx'],
  ),
];

const kProjectFileTypes = <XTypeGroup>[
  XTypeGroup(
    label: "IJAF Project File (*.phase)",
    extensions: ["phase"],
  )
];
