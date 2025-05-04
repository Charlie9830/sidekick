// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    Excel? document,
    Set<String>? sheetNames,
  }) {
    return ImportState(
      document: document ?? this.document,
      sheetNames: sheetNames ?? this.sheetNames,
    );
  }
}
