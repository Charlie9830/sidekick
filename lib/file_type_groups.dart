import 'package:file_selector/file_selector.dart';

const kExcelFileTypes = <XTypeGroup>[
  XTypeGroup(
    label: "Excel Files (*.xls, *.xlsx)",
    extensions: ['xls', 'xlsx'],
  ),
];

const kProjectFileExtension = "phase";

const kProjectFileTypes = <XTypeGroup>[
  XTypeGroup(
    label: "IJAF Project File (*.$kProjectFileExtension)",
    extensions: [kProjectFileExtension],
  )
];