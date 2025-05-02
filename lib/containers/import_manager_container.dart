import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/enums.dart';
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
        final rowPairings = _selectRowPairings(store);
        final incomingRowVms = _selectRawIncomingRows(store);
        final selectedIncomingRowErrors =
            _selectRowErrors(incomingRowVms, store);

        return ImportManagerViewModel(
          settings: store.state.fileState.importSettings,
          sheetNames: store.state.importState.sheetNames.toList(),
          incomingRowVms: incomingRowVms,
          rowPairings: rowPairings.values.toList(),
          onRefreshButtonPressed: () =>
              store.dispatch(readInitialRawPatchData()),
          onRowSelectionChanged: (item) =>
              store.dispatch(SetSelectedRawPatchRow(item)),
          selectedRow: store.state.navstate.selectedRawPatchRow,
          rowErrors: selectedIncomingRowErrors,
          step: store.state.navstate.importManagerStep,
          onNextStep: (nextStep) =>
              store.dispatch(SetImportManagerStep(nextStep)),
          onFixtureDatabaseFilePathChanged: (path) =>
              store.dispatch(updateFixtureDatabaseFilePath(path)),
          onFixtureMappingPathChanged: (path) =>
              store.dispatch(updateFixtureMappingFilePath(path)),
          fixtureDatabaseFilePath:
              store.state.fileState.fixtureTypeDatabasePath,
          fixtureMappingFilePath: store.state.fileState.fixtureMappingFilePath,
        );
      },
    );
  }

  List<PatchDataItemError> _selectRowErrors(
      List<RawRowViewModel> incomingRowVms, Store<AppState> store) {
    return incomingRowVms
        .where(
            (vm) => vm.selectionId == store.state.navstate.selectedRawPatchRow)
        .map((vm) => vm.row.errors)
        .flattened
        .toList();
  }

  List<RawRowViewModel> _selectRawIncomingRows(Store<AppState> store) {
    return store.state.importState.rawPatchData.map((row) {
      return RawRowViewModel(
        row: row,
        selectionId: '${row.rowNumber.toString()}-row_number_based_id',
      );
    }).toList();
  }

  Map<String, RowPairViewModel> _selectRowPairings(Store<AppState> store) {
    final existingFixturesByFid = Map<int, FixtureModel>.fromEntries(store
        .state.fixtureState.fixtures.values
        .map((fixture) => MapEntry(fixture.fid, fixture)));

    return Map<String, RowPairViewModel>.fromEntries(
        store.state.importState.rawPatchData.map((incoming) {
      final parsedFid = int.tryParse(incoming.fid);
      final existingFixture =
          parsedFid != null ? existingFixturesByFid[parsedFid] : null;

      final selectionId = _computeSelectionId(existingFixture, incoming);

      return MapEntry(
          selectionId,
          RowPairViewModel(
              selectionId: selectionId,
              incoming: incoming,
              existing: existingFixture != null
                  ? FixtureViewModel(
                      existingFixture: existingFixture,
                      locationName: store.state.fixtureState
                              .locations[existingFixture.locationId]?.name ??
                          '',
                      fixtureTypeName: store.state.fixtureState
                              .fixtureTypes[existingFixture.typeId]?.name ??
                          '',
                    )
                  : null));
    }));
  }

  String _computeSelectionId(
      FixtureModel? existingFixture, RawRowData incoming) {
    return existingFixture != null
        ? existingFixture.uid
        : '${incoming.fid}-incoming-id';
  }
}
