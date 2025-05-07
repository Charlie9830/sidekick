// ignore_for_file: public_member_api_docs, sort_constructors_first
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
      : fixtureState = const FixtureState.initial(),
        navstate = const NavigationState.initial(),
        fileState = const FileState.initial();

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

class DiffAppState extends AppState {
  DiffAppState({
    required super.fixtureState,
    super.navstate = const NavigationState.initial(),
    super.fileState = const FileState.initial(),
  });

  DiffAppState.initial() : super.initial();

  @override
  DiffAppState copyWith({
    FixtureState? fixtureState,
    NavigationState? navstate,
    FileState? fileState,
  }) {
    return DiffAppState(
      fixtureState: fixtureState ?? this.fixtureState,
    );
  }
}
