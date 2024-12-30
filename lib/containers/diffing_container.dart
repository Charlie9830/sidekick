import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/diffing.dart';
import 'package:sidekick/view_models/diffing_view_model.dart';

class DiffingContainer extends StatelessWidget {
  const DiffingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, DiffingViewModel>(
      builder: (context, viewModel) {
        return Diffing(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return DiffingViewModel(
          selectedTab: store.state.navstate.selectedDiffingTab,
          onDiffingTabChanged: (newIndex) =>
              store.dispatch(SetSelectedDiffingTab(newIndex)),
        );
      },
    );
  }
}
