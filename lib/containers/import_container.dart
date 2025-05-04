import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/import_module/import.dart';
import 'package:sidekick/view_models/import_view_model.dart';

class ImportContainer extends StatelessWidget {
  const ImportContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ImportViewModel>(
      builder: (context, viewModel) {
        return Import(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return ImportViewModel(
          importFilePath: store.state.fileState.fixturePatchImportPath,
          onFileSelected: (path) =>
              store.dispatch(setImportPath(context, path)),
          onImportButtonPressed: () => store.dispatch(importPatchFile(context)),
          sheetNames: store.state.importState.sheetNames.toList(),
          onImportManagerButtonPressed: () => store.dispatch(showImportManager(context)),
        );
      },
    );
  }
}
