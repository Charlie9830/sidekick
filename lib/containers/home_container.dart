import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
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
            fixtures: store.state.fixtureState.fixtures,
            locations: store.state.fixtureState.locations,
            onAppInitialize: () => store.dispatch(initializeApp()));
      },
    );
  }
}
