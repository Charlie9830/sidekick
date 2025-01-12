// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/state/diffing_state.dart';
import 'package:sidekick/redux/state/file_state.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/state/import_state.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

class AppState {
  final FixtureState fixtureState;
  final NavigationState navstate;
  final FileState fileState;
  final DiffingState diffingState;
  final ImportState importState;

  AppState({
    required this.fixtureState,
    required this.navstate,
    required this.fileState,
    required this.diffingState,
    required this.importState,
  });

  AppState.initial()
      : fixtureState = FixtureState.initial(),
        navstate = NavigationState.initial(),
        fileState = FileState.initial(),
        diffingState = DiffingState.initial(),
        importState = ImportState.initial();

  AppState copyWith({
    FixtureState? fixtureState,
    NavigationState? navstate,
    FileState? fileState,
    DiffingState? diffingState,
    ImportState? importState,
  }) {
    return AppState(
      fixtureState: fixtureState ?? this.fixtureState,
      navstate: navstate ?? this.navstate,
      fileState: fileState ?? this.fileState,
      diffingState: diffingState ?? this.diffingState,
      importState: importState ?? this.importState,
    );
  }
}
