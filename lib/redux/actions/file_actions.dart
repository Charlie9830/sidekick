import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;

import 'package:sidekick/containers/import_manager_container.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/init_persistent_settings_storage.dart';
import 'package:sidekick/persistent_settings/update_persistent_settings.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/file/import_module/import_manager_result.dart';
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/toasts.dart';

ThunkAction<AppState> updateFixtureDatabaseFilePath(String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureTypeDatabasePath(path));

    await updatePersistentSettings(
      (existing) => existing.copyWith(fixtureTypeDatabasePath: path),
    );
  };
}

ThunkAction<AppState> updateFixtureMappingFilePath(String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureMappingFilePath(path));

    await updatePersistentSettings(
      (existing) => existing.copyWith(fixtureMappingFilePath: path),
    );
  };
}

ThunkAction<AppState> showImportManager(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await showDialog(
      context: context,
      fullScreen: true,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.background,
      builder: (innerContext) => const ImportManagerContainer(),
    );

    if (result is ImportManagerResult) {
      store.dispatch(
        SetImportedFixtureData(
          fixtures: result.fixtures.toModelMap(),
          locations: result.locations.toModelMap(),
          fixtureTypes: result.fixtureTypes.toModelMap(),
          trusses: result.trusses.toModelMap(),
        ),
      );

      if (context.mounted) {
        showGenericSuccessToast(context: context, title: "Patch imported.");
      }
    } else {
      store.dispatch(SetImportManagerStep(ImportManagerStep.fileSelect));
    }
  };
}

ThunkAction<AppState> debugButtonPressed() {
  return (Store<AppState> store) async {};
}

ThunkAction<AppState> initializeApp(BuildContext context) {
  return (Store<AppState> store) async {
    // Fetch Persistent Settings.
    await initPersistentSettingsStorage();
    final persistentSettings = await fetchPersistentSettings();

    // Set the Fixture Database Path value, and load the Fixture Database if we can.
    if (persistentSettings.fixtureTypeDatabasePath.isNotEmpty) {
      store.dispatch(
        SetFixtureTypeDatabasePath(persistentSettings.fixtureTypeDatabasePath),
      );
    }

    // Load the Fixture Mapping Path.
    if (persistentSettings.fixtureMappingFilePath.isNotEmpty) {
      store.dispatch(
        SetFixtureMappingFilePath(persistentSettings.fixtureMappingFilePath),
      );
    }
  };
}

ThunkAction<AppState> startNewProject(BuildContext context, bool saveCurrent) {
  return (Store<AppState> store) async {
    if (saveCurrent) {
      store.dispatch(saveProjectFile(context, SaveType.save));
    }

    store.dispatch(NewProject());

    diffAppStore.dispatch(NewProject());
  };
}

ThunkAction<AppState> openProjectFile(
  BuildContext context,
  bool saveCurrent,
  String path,
) {
  return (Store<AppState> store) async {
    final projectFile = await deserializeProjectFile(path);

    store.dispatch(
      OpenProject(
        project: projectFile,
        parentDirectory: p.dirname(path),
        path: path,
      ),
    );

    // Reset the Diff App State.
    if (store is! Store<DiffAppState>) {
      diffAppStore.dispatch(NewProject());
    }
  };
}

ThunkAction<AppState> saveProjectFile(BuildContext context, SaveType saveType) {
  return (Store<AppState> store) async {
    final saveAsNeeded =
        store.state.fileState.projectFilePath.isEmpty ||
        saveType == SaveType.saveAs;

    String targetFilePath = store.state.fileState.projectFilePath;

    // If a save as is required, collect the new File path and store it to target File Path.
    if (saveAsNeeded == true) {
      // Post a dialog to collect the new file location.
      final selectedFilePath = await getSaveLocation(
        acceptedTypeGroups: kProjectFileTypes,
        initialDirectory:
            await Directory(
              store.state.fileState.lastUsedProjectDirectory,
            ).exists()
            ? store.state.fileState.lastUsedProjectDirectory
            : null,
        confirmButtonText: 'Save As',
      );

      if (selectedFilePath == null || selectedFilePath.path.isEmpty) {
        return;
      }

      targetFilePath = selectedFilePath.path;
    }

    try {
      // Ensure the file path contains the correct extension.
      if (p.extension(targetFilePath).trim() != '.$kProjectFileExtension') {
        targetFilePath = '$targetFilePath.$kProjectFileExtension';
      }

      // Perform the File Operations.
      var newMetadata = await serializeProjectFile(store.state, targetFilePath);

      // Save the updated Metadata.
      store.dispatch(SetProjectFileMetadata(newMetadata));
      store.dispatch(SetLastUsedProjectDirectory(p.dirname(targetFilePath)));
      store.dispatch(SetProjectFilePath(targetFilePath));

      if (context.mounted) {
        showFileSaveSuccessToast(context: context);
      }
    } catch (e) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'An error occured.',
          subtitle: 'Project saving failed.',
          extendedMessage: e.toString(),
        );
      }
    }
  };
}

String getTestDataPath() {
  const String testDataDirectory = './test_data/';
  const String testFileName = 'fixtures.xlsx';
  final String testDataPath = p.join(testDataDirectory, testFileName);
  return testDataPath;
}
