import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
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
          lastUsedExportDirectory:
              store.state.fileState.projectMetadata.lastUsedExportDirectory,
          projectName: store.state.fileState.projectMetadata.projectName,
          onProjectNameChanged: (newValue) =>
              store.dispatch(UpdateProjectName(newValue)),
          onExportButtonPressed: () => store.dispatch(export(context)),
          onChooseExportDirectoryButtonPressed: () =>
              store.dispatch(chooseExportDirectory(context)),
          onOpenAfterExportChanged: (newValue) =>
              store.dispatch(SetOpenAfterExport(newValue!)),
          openAfterExport: store.state.navstate.openAfterExport,
        );
      },
    );
  }
}
