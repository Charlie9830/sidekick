import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';

class LoomsDiffingContainer extends StatelessWidget {
  const LoomsDiffingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomDiffingViewModel>(
      builder: (context, viewModel) {
        return const Text('Stubbed');
      },
      converter: (Store<AppState> store) {
        return LoomDiffingViewModel(
          itemVms: [],
        );
      },
    );
  }
}
