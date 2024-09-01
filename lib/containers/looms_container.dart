import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms.dart';
import 'package:sidekick/view_models/loom_row_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class LoomsContainer extends StatelessWidget {
  const LoomsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomsViewModel>(
        builder: (context, viewModel) {
      return Looms(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      return LoomsViewModel(
        rowVms: _selectLoomRows(store),
      );
    });
  }

  List<LoomRowViewModel> _selectLoomRows(Store<AppState> store) {
    return store.state.fixtureState.looms.values.map((loom) {
      return LoomRowViewModel(
          loom: loom,
          locationName:
              store.state.fixtureState.locations[loom.locationId]?.name ??
                  'NONE');
    }).toList();
  }
}
