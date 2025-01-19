import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/import_module/import_manager.dart';
import 'package:sidekick/view_models/import_manager_view_model.dart';

class ImportManagerContainer extends StatelessWidget {
  const ImportManagerContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ImportManagerViewModel>(
      builder: (context, viewModel) {
        return ImportManager(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return ImportManagerViewModel(
          importFilePath: store.state.fileState.fixturePatchImportPath,
          settings: store.state.fileState.importSettings,
          sheetNames: store.state.importState.sheetNames.toList(),
          rowPairings: _selectRowPairings(store),
          onRefreshButtonPressed: () =>
              store.dispatch(readInitialRawPatchData()),
          onRowSelectionChanged: (item) =>
              store.dispatch(SetSelectedRawPatchRow(item)),
          selectedRow: store.state.navstate.selectedRawPatchRow,
          rowErrors: _selectErrors(store),
        );
      },
    );
  }

  List<RowPairViewModel> _selectRowPairings(Store<AppState> store) {
    final existingFixturesByFid = Map<int, FixtureModel>.fromEntries(store
        .state.fixtureState.fixtures.values
        .map((fixture) => MapEntry(fixture.fid, fixture)));

    return store.state.importState.rawPatchData.map((incoming) {
      final parsedFid = int.tryParse(incoming.fid);
      final existingFixture =
          parsedFid != null ? existingFixturesByFid[parsedFid] : null;
      return RowPairViewModel(
          selectionId: existingFixture != null
              ? existingFixture.uid
              : '${incoming.fid}-incoming-id',
          incoming: incoming,
          existing: existingFixture != null
              ? FixtureViewModel(
                  fixture: existingFixture,
                  locationName: store.state.fixtureState
                          .locations[existingFixture.locationId]?.name ??
                      '',
                  fixtureTypeName: store.state.fixtureState
                          .fixtureTypes[existingFixture.typeId]?.name ??
                      '',
                )
              : null);
    }).toList();
  }

  List<PatchDataItemError> _selectErrors(Store<AppState> store) {
    if (store.state.navstate.selectedRawPatchRow == -1) {
      return [];
    }

    final row = store.state.importState.rawPatchData.firstWhereOrNull(
        (item) => item.rowNumber == store.state.navstate.selectedRawPatchRow);

    if (row == null) {
      return [];
    }

    return row.errors.toList();
  }
}
