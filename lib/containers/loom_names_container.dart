import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/loom_names/loom_names.dart';
import 'package:sidekick/view_models/loom_names_view_model.dart';

class LoomNamesContainer extends StatelessWidget {
  const LoomNamesContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomNamesViewModel>(
      builder: (context, viewModel) {
        return LoomNames(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return LoomNamesViewModel(
          outlets: store.state.fixtureState.outlets,
          locations: store.state.fixtureState.locations,
          onMultiPrefixChanged: (location, newValue) => store.dispatch(
            UpdateLocationMultiPrefix(location, newValue),
          ),
          onCommitPowerPressed: (location) => store.dispatch(CommitLocationPowerPatch(location))
        );
      },
    );
  }
}
