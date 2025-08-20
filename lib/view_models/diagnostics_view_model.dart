import 'package:sidekick/redux/state/app_state.dart';

class DiagnosticsViewModel {
  final AppState appState;
  final void Function() onDebugAction;

  DiagnosticsViewModel({
    required this.appState,
    required this.onDebugAction,
  });
}
