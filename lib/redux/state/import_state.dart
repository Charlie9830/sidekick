// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:excel/excel.dart';

import 'package:sidekick/excel/new/raw_row_data.dart';

class ImportState {
  final Excel document;
  Set<String> sheetNames;
  final List<RawRowData> rawPatchData;

  ImportState({
    required this.document,
    required this.sheetNames,
    required this.rawPatchData,
  });

  ImportState.initial()
      : sheetNames = const {},
        document = Excel.createExcel(),
        rawPatchData = const [];

  ImportState copyWith({
    Excel? document,
    Set<String>? sheetNames,
    List<RawRowData>? rawPatchData,
  }) {
    return ImportState(
      document: document ?? this.document,
      sheetNames: sheetNames ?? this.sheetNames,
      rawPatchData: rawPatchData ?? this.rawPatchData,
    );
  }
}
