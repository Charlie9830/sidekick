import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/file_state.dart';

FileState fileStateReducer(FileState state, dynamic action) {
  return switch (action) {
    SetImportFilePath a => state.copyWith(fixtureImportPath: a.path),
    _ => state
  };
}
