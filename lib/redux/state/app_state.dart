import 'package:sidekick/redux/state/file_state.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

class AppState {
  final FixtureState fixtureState;
  final NavigationState navstate;
  final FileState fileState;

  AppState({
    required this.fixtureState,
    required this.navstate,
    required this.fileState,
  });

  AppState.initial()
      : fixtureState = FixtureState.initial(),
        navstate = NavigationState.initial(),
        fileState = FileState.initial();

  AppState copyWith({
    FixtureState? fixtureState,
    NavigationState? navstate,
    FileState? fileState,
  }) {
    return AppState(
      fixtureState: fixtureState ?? this.fixtureState,
      navstate: navstate ?? this.navstate,
      fileState: fileState ?? this.fileState,
    );
  }
}
