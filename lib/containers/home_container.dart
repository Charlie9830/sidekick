import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/home/home.dart';
import 'package:sidekick/view_models/home_view_model.dart';

class HomeContainer extends StatelessWidget {
  const HomeContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, HomeViewModel>(
      builder: (context, viewModel) {
        return Home(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return HomeViewModel(
            onDebugAction: () => store.dispatch(debugButtonPressed()),
            selectedFixtureIds: store.state.navstate.selectedFixtureIds,
            onSelectedFixturesChanged: (ids) =>
                store.dispatch(SetSelectedFixtureIds(ids)),
            onAppInitialize: () => store.dispatch(initializeApp(context)),
            onSetSequenceButtonPressed: () =>
                store.dispatch(setSequenceNumbers(context)));
      },
    );
  }
}
