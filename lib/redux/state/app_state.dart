import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

class AppState {
  final FixtureState fixtureState;
  final NavigationState navstate;

  AppState({
    required this.fixtureState,
    required this.navstate,
  });

  AppState.initial()
      : fixtureState = FixtureState.initial(),
        navstate = NavigationState.initial();

  AppState copyWith({
    FixtureState? fixtureState,
    NavigationState? navstate,
  }) {
    return AppState(
      fixtureState: fixtureState ?? this.fixtureState,
      navstate: navstate ?? this.navstate,
    );
  }
}
