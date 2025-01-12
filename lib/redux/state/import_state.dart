import 'package:excel/excel.dart';

class ImportState {
  final Excel document;
  Set<String> sheetNames;

  ImportState({
    required this.document,
    required this.sheetNames,
  });

  ImportState.initial()
      : sheetNames = const {},
        document = Excel.createExcel();

  ImportState copyWith({
    Set<String>? sheetNames,
    String? selectedSheet,
    Excel? document,
  }) {
    return ImportState(
      sheetNames: sheetNames ?? this.sheetNames,
      document: document ?? this.document,
    );
  }
}
