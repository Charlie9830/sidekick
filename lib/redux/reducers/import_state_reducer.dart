import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/import_state.dart';

ImportState importStateReducer(ImportState state, dynamic action) {
  if (action is OpenProject) {
    return ImportState.initial();
  }

  if (action is NewProject) {
    return ImportState.initial();
  }

  if (action is SetSelectedExcelSheet) {
    return state.copyWith(selectedSheet: action.value);
  }

  if (action is SetExcelSheetNames) {
    return state.copyWith(
      sheetNames: action.value,
    );
  }

  return state;
}
