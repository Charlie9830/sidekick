import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/file_screen.dart';
import 'package:sidekick/view_models/file_view_model.dart';

class FileContainer extends StatelessWidget {
  const FileContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FileViewModel>(
        builder: (context, viewModel) {
      return FileScreen(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      return FileViewModel(
        onNewProjectButtonPressed: (saveCurrent) =>
            store.dispatch(startNewProject(context, saveCurrent)),
        onOpenProjectButtonPressed: (saveCurrent, path) =>
            store.dispatch(openProjectFile(context, saveCurrent, path)),
        onSaveProjectButtonPressed: (saveType) =>
            store.dispatch(saveProjectFile(context, saveType)),
        projectFilePath: store.state.fileState.projectFilePath,
        fixtureTypeDatabasePath: store.state.fileState.fixtureTypeDatabasePath,
        isFixtureTypeDatabasePathValid:
            store.state.fileState.isFixtureTypeDatabasePathValid,
      );
    });
  }
}
