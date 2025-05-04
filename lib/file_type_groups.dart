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
    label: "Phase Project File (*.$kProjectFileExtension)",
    extensions: [kProjectFileExtension],
  )
];

const kMvrFileTypes = <XTypeGroup>[
  XTypeGroup(
    label: "MVR Files (*.mvr)",
    extensions: ['mvr'],
  )
];

const kXmlFileTypes = <XTypeGroup>[
  XTypeGroup(label: "XML Files (*.xml)", extensions: ['xml'])
];
