import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/import_module/import_manager.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
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
          step: store.state.navstate.importManagerStep,
          goToStep: (nextStep) =>
              store.dispatch(SetImportManagerStep(nextStep)),
          onFixtureDatabaseFilePathChanged: (path) =>
              store.dispatch(updateFixtureDatabaseFilePath(path)),
          onFixtureMappingPathChanged: (path) =>
              store.dispatch(updateFixtureMappingFilePath(path)),
          fixtureDatabaseFilePath:
              store.state.fileState.fixtureTypeDatabasePath,
          fixtureMappingFilePath: store.state.fileState.fixtureMappingFilePath,
          existingFixtureViewModels: _selectExistingFixtureViewModels(store),
          existingLocations: store.state.fixtureState.locations,
          existingFixtureTypes: store.state.fixtureState.fixtureTypes,
          existingFixtures: store.state.fixtureState.fixtures,
        );
      },
    );
  }

  Map<String, FixtureViewModel> _selectExistingFixtureViewModels(
      Store<AppState> store) {
    return Map<String, FixtureViewModel>.fromEntries(
      store.state.fixtureState.fixtures.values.map(
        (fixture) => MapEntry(
          fixture.uid,
          FixtureViewModel(
            fid: fixture.fid,
            type: store.state.fixtureState.fixtureTypes[fixture.typeId]
                    ?.shortName ??
                '',
            address: fixture.dmxAddress.toSlashNotationString(),
            uid: fixture.uid,
            mode: fixture.mode,
            location:
                store.state.fixtureState.locations[fixture.locationId]?.name ??
                    '',
            sequence: fixture.sequence,
          ),
        ),
      ),
    );
  }
}
