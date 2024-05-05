import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/export/export.dart';

import 'package:sidekick/view_models/export_view_model.dart';

class ExportContainer extends StatelessWidget {
  const ExportContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ExportViewModel>(
      builder: (context, viewModel) {
        return Export(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return ExportViewModel(
            outlets: store.state.fixtureState.outlets,
            locations: store.state.fixtureState.locations,
            onCopyPowerPatchToClipboard: () =>
                store.dispatch(copyPowerPatchToClipboard(context)));
      },
    );
  }
}
