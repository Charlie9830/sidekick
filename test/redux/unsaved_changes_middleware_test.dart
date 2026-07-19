import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/middleware/unsaved_changes_middleware.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/reducers/app_state_reducer.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

/// Builds a store wired exactly as `appStore` is, minus the thunk middleware.
Store<AppState> buildStore() => Store<AppState>(
  appStateReducer,
  initialState: AppState.initial(),
  middleware: [unsavedChangesMiddleware],
);

/// An otherwise-empty project file, standing in for one loaded from disk.
ProjectFileModel buildEmptyProjectFile() => ProjectFileModel(
  metadata: const ProjectFileMetadataModel.initial(),
  fixtures: const [],
  powerMultiOutlets: const [],
  dataMultis: const [],
  dataPatches: const [],
  locations: const [],
  looms: const [],
  cables: const [],
  maxSequenceBreak: 4,
  balanceTolerance: 0.5,
  defaultPowerMulti: CableType.socapex,
  loomStock: const [],
  fixtureTypes: const [],
  hoists: const [],
  hoistControllers: const [],
  hoistMultis: const [],
  powerFeeds: const [],
  powerRacks: const [],
  powerRackTypes: const [],
  dataRackTypes: const [],
  dataRacks: const [],
  fixtureTypePools: const [],
);

void main() {
  group('unsavedChangesMiddleware', () {
    test('a fixture-mutating action marks the project dirty', () {
      final store = buildStore();

      expect(store.state.fileState.hasUnsavedChanges, isFalse);

      store.dispatch(SetMaxSequenceBreak('12'));

      expect(store.state.fileState.hasUnsavedChanges, isTrue);
    });

    test('an action that leaves fixture state alone does not', () {
      final store = buildStore();

      store.dispatch(SetIsValidatingExportData(true));

      expect(store.state.fileState.hasUnsavedChanges, isFalse);
    });

    test('the flag is only dispatched once while already dirty', () {
      final dispatched = <dynamic>[];
      final store = Store<AppState>(
        appStateReducer,
        initialState: AppState.initial(),
        middleware: [
          (store, action, next) {
            dispatched.add(action);
            next(action);
          },
          unsavedChangesMiddleware,
        ],
      );

      store.dispatch(SetMaxSequenceBreak('12'));
      store.dispatch(SetMaxSequenceBreak('13'));
      store.dispatch(SetMaxSequenceBreak('14'));

      expect(dispatched.whereType<SetHasUnsavedChanges>(), hasLength(1));
    });

    test('NewProject clears the flag rather than re-dirtying', () {
      final store = buildStore();

      store.dispatch(SetMaxSequenceBreak('12'));
      expect(store.state.fileState.hasUnsavedChanges, isTrue);

      store.dispatch(NewProject());

      expect(store.state.fileState.hasUnsavedChanges, isFalse);
    });

    test('OpenProject clears the flag rather than re-dirtying', () {
      final store = buildStore();

      store.dispatch(SetMaxSequenceBreak('12'));
      expect(store.state.fileState.hasUnsavedChanges, isTrue);

      store.dispatch(
        OpenProject(
          project: buildEmptyProjectFile(),
          parentDirectory: '/projects',
          path: '/projects/show.phase',
        ),
      );

      expect(store.state.fileState.hasUnsavedChanges, isFalse);
    });

    test('SetProjectFileMetadata clears the flag after a save', () {
      final store = buildStore();

      store.dispatch(SetMaxSequenceBreak('12'));
      expect(store.state.fileState.hasUnsavedChanges, isTrue);

      store.dispatch(
        SetProjectFileMetadata(const ProjectFileMetadataModel.initial()),
      );

      expect(store.state.fileState.hasUnsavedChanges, isFalse);
    });

    test('the post-save path actions do not re-dirty the project', () {
      final store = buildStore();

      store.dispatch(SetMaxSequenceBreak('12'));

      // Mirrors the dispatch order of saveProject after a successful write.
      store.dispatch(
        SetProjectFileMetadata(const ProjectFileMetadataModel.initial()),
      );
      store.dispatch(SetLastUsedProjectDirectory('/projects'));
      store.dispatch(SetProjectFilePath('/projects/show.phase'));

      expect(store.state.fileState.hasUnsavedChanges, isFalse);
    });
  });
}
