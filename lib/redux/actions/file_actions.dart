import 'dart:convert';
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
import 'package:sidekick/serialization/project_file_metadata_model.dart';
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
          fixtureGeometries: result.fixtureGeometries.toModelMap(),
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
      final result = await _saveProjectFile(
        projectFilePath: store.state.fileState.projectFilePath,
        lastUsedProjectDirectory:
            store.state.fileState.lastUsedProjectDirectory,
        state: store.state,
      );

      // User Cancelled Save
      if (result is _WriteProjectCancel) {
        return;
      }

      // File Saved Succesfully.
      if (result is _WriteProjectSuccess) {
        store.dispatch(SetProjectFileMetadata(result.metadata));
        store.dispatch(
          SetLastUsedProjectDirectory(result.lastUsedProjectDirectory),
        );
        store.dispatch(SetProjectFilePath(result.projectFilePath));

        if (context.mounted) {
          showFileSaveSuccessToast(context: context);
        }
      }

      // An error occurred.
      if (result is _WriteProjectError) {
        if (context.mounted) {
          showGenericErrorToast(
            context: context,
            title: 'An error occured.',
            subtitle: 'Project saving failed.',
            extendedMessage: result.message,
          );
        }
      }
    }

    store.dispatch(NewProject());

    diffAppStore.dispatch(NewProject());
  };
}

/// Opens a project file into [store].
///
/// When [path] is provided (e.g. from a drag-and-drop) the file open dialog is
/// skipped and that file is loaded directly. When dispatched on the
/// [diffAppStore], the file loads into the diffing store and its path is
/// recorded on the live [appStore] as the comparison file path.
ThunkAction<AppState> openProjectFile(
  BuildContext context,
  bool saveCurrent, {
  String? path,
}) {
  return (Store<AppState> store) async {
    if (saveCurrent) {
      final result = await _saveProjectFile(
        projectFilePath: store.state.fileState.projectFilePath,
        lastUsedProjectDirectory:
            store.state.fileState.lastUsedProjectDirectory,
        state: store.state,
      );

      // User Cancelled Save
      if (result is _WriteProjectCancel) {
        return;
      }

      // File Saved Succesfully.
      if (result is _WriteProjectSuccess) {
        store.dispatch(SetProjectFileMetadata(result.metadata));
        store.dispatch(
          SetLastUsedProjectDirectory(result.lastUsedProjectDirectory),
        );
        store.dispatch(SetProjectFilePath(result.projectFilePath));
      }

      // An error occurred.
      if (result is _WriteProjectError) {
        if (context.mounted) {
          showGenericErrorToast(
            context: context,
            title: 'An error occured.',
            subtitle: 'Project saving failed.',
            extendedMessage: result.message,
          );
        }

        return;
      }
    }

    // Use the provided path (e.g. drag-and-drop), otherwise show the open
    // file dialog.
    final selectedFilePath =
        path ??
        (await openFile(acceptedTypeGroups: kProjectFileTypes))?.path;

    if (selectedFilePath == null) {
      return;
    }

    final projectFile = await deserializeProjectFile(selectedFilePath);

    store.dispatch(
      OpenProject(
        project: projectFile,
        parentDirectory: p.dirname(selectedFilePath),
        path: selectedFilePath,
      ),
    );

    if (store is Store<DiffAppState>) {
      // Loaded a comparison file into the diffing store; record its path on the
      // live store so the diffing UI can display which file is being compared.
      appStore.dispatch(SetComparisonFilePath(selectedFilePath));
    } else {
      // Opened a new live project, so the existing comparison is stale.
      diffAppStore.dispatch(NewProject());
    }

    if (context.mounted) {
      showGenericSuccessToast(
        context: context,
        icon: Icon(Icons.file_open),
        title: '${p.basename(selectedFilePath)} opened.',
      );
    }
  };
}

ThunkAction<AppState> saveProjectFile(
  BuildContext context,
  SaveType saveTypeOverride,
) {
  return (Store<AppState> store) async {
    // Save the Project.
    final result = await _saveProjectFile(
      projectFilePath: store.state.fileState.projectFilePath,
      lastUsedProjectDirectory: store.state.fileState.lastUsedProjectDirectory,
      saveTypeOverride: saveTypeOverride,
      state: store.state,
    );

    // File Saved Succesfully.
    if (result is _WriteProjectSuccess) {
      store.dispatch(SetProjectFileMetadata(result.metadata));
      store.dispatch(
        SetLastUsedProjectDirectory(result.lastUsedProjectDirectory),
      );
      store.dispatch(SetProjectFilePath(result.projectFilePath));

      if (context.mounted) {
        showFileSaveSuccessToast(context: context);
      }
    }

    // An error occurred.
    if (result is _WriteProjectError) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'An error occured.',
          subtitle: 'Project saving failed.',
          extendedMessage: result.message,
        );
      }
    }
  };
}

Future<_WriteProjectResult> _saveProjectFile({
  required String projectFilePath,
  required String lastUsedProjectDirectory,
  SaveType saveTypeOverride = SaveType.save,
  required AppState state,
}) async {
  // Collect the target file path of the save, this could be over an existing Save, or as a Save As operation.
  final targetFilePath = switch (saveTypeOverride) {
    // If we don't have an existing valid path, then this is the first save and thus we need to follow the 'save as' procedure.
    SaveType.save =>
      projectFilePath.isNotEmpty
          ? projectFilePath
          : await _postSaveAsDialog(
              lastUsedProjectDirectory: lastUsedProjectDirectory,
              currentFileName: p.basename(projectFilePath),
            ),
    SaveType.saveAs => await _postSaveAsDialog(
      lastUsedProjectDirectory: lastUsedProjectDirectory,
      currentFileName: p.basename(projectFilePath),
    ),
  };

  if (targetFilePath.isEmpty) {
    // If the Target file path is still empty, the user likely cancelled the 'Save as' dilaog.
    return _WriteProjectCancel();
  }

  return await _writeProjectFile(targetFilePath: targetFilePath, state: state);
}

Future<String> _postSaveAsDialog({
  required String lastUsedProjectDirectory,
  required String currentFileName,
}) async {
  final selectedFilePath = await getSaveLocation(
    acceptedTypeGroups: kProjectFileTypes,
    suggestedName: currentFileName.isNotEmpty ? currentFileName : null,
    initialDirectory: await Directory(lastUsedProjectDirectory).exists()
        ? lastUsedProjectDirectory
        : null,
    confirmButtonText: 'Save As',
  );

  if (selectedFilePath == null || selectedFilePath.path.isEmpty) {
    return '';
  }

  return selectedFilePath.path;
}

Future<_WriteProjectResult> _writeProjectFile({
  required String targetFilePath,
  required AppState state,
}) async {
  // Ensure the Target File Path carries the correct extension.
  if (p.extension(targetFilePath).trim() != '.$kProjectFileExtension') {
    targetFilePath = '$targetFilePath.$kProjectFileExtension';
  }

  try {
    // Perform the File Operations.
    var newMetadata = await serializeProjectFile(state, targetFilePath);

    print('Saved ${DateTime.now().second}');

    return _WriteProjectSuccess(
      metadata: newMetadata,
      lastUsedProjectDirectory: p.dirname(targetFilePath),
      projectFilePath: targetFilePath,
    );
  } on FileSystemException catch (e) {
    return _WriteProjectError(message: e.message);
  } catch (e) {
    return _WriteProjectError(
      message: 'Unknown error occurred. ${e.toString()}',
    );
  }
}

String getTestDataPath() {
  const String testDataDirectory = './test_data/';
  const String testFileName = 'fixtures.xlsx';
  final String testDataPath = p.join(testDataDirectory, testFileName);
  return testDataPath;
}

sealed class _WriteProjectResult {}

class _WriteProjectSuccess extends _WriteProjectResult {
  final ProjectFileMetadataModel metadata;
  final String lastUsedProjectDirectory;
  final String projectFilePath;

  _WriteProjectSuccess({
    required this.metadata,
    required this.lastUsedProjectDirectory,
    required this.projectFilePath,
  });
}

class _WriteProjectError extends _WriteProjectResult {
  final String message;

  _WriteProjectError({required this.message});
}

class _WriteProjectCancel extends _WriteProjectResult {}
