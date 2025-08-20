import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/diagnostics_screen.dart';
import 'package:sidekick/view_models/diagnostics_view_model.dart';

class DiagnosticsContainer extends StatelessWidget {
  const DiagnosticsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, DiagnosticsViewModel>(
        builder: (context, viewModel) {
      return DiagnosticsScreen(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      return DiagnosticsViewModel(
          appState: store.state,
          onDebugAction: () => store.dispatch(debugButtonPressed()));
    });
  }
}
