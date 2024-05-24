import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/data_patch/data_patch.dart';
import 'package:sidekick/view_models/data_patch_view_model.dart';

class DataPatchContainer extends StatelessWidget {
  const DataPatchContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, DataPatchViewModel>(
      builder: (context, viewModel) {
        return DataPatch(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return DataPatchViewModel(
          rows: _selectDataPatchRows(store),
          onCommit: () => store.dispatch(commitDataPatch()),
          onGeneratePatchPressed: () => store.dispatch(generateDataPatch()),
        );
      },
    );
  }

  List<DataPatchRow> _selectDataPatchRows(Store<AppState> store) {
    return store.state.fixtureState.locations.values
        .map((location) {
          final associatedMultis = store.state.fixtureState.dataMultis.values
              .where((multi) => multi.locationId == location.uid)
              .toList();

          final singlePatches = store.state.fixtureState.dataPatches.values
              .where((patch) =>
                  patch.locationId == location.uid && patch.multiId.isEmpty);

          return [
            LocationRow(location),
            ...associatedMultis.map(
              (multi) => DataMultiRow(
                multi: multi,
                patches: store.state.fixtureState.dataPatches.values
                    .where((patch) => patch.multiId == multi.uid)
                    .toList(),
              ),
            ),
            ...singlePatches.map((patch) => SingleDataPatchRow(patch)),
          ];
        })
        .flattened
        .toList();
  }
}
