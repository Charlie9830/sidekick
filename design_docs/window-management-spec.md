# Window Management — Unsaved Changes Interception

**Status:** Draft for review
**Date:** 2026-07-13
**Scope:** Desktop targets (Windows now, macOS forthcoming). Web is excluded —
`window_manager` does not support it and browser close interception is a
different mechanism (`beforeunload`).

## Goal

When the user attempts to close the application window (or quit the app on
macOS) while there are unsaved project changes, intercept the close and prompt
them to **Save**, **Discard**, or **Cancel**. If there are no unsaved changes,
the window closes immediately with no prompt.

---

## 1. Unsaved-changes tracking (Redux middleware)

### Approach

Add a middleware to `appStore` that watches for changes to
`AppState.fixtureState` and flags the file as dirty. This works because of an
existing property of the reducer chain: `fixtureStateReducer`
([fixture_state_reducer.dart](lib/redux/reducers/fixture_state_reducer.dart))
returns the *identical* `FixtureState` instance when no sub-reducer handles
the action, and `appStateReducer` passes that reference through `copyWith`
unchanged. So an `identical()` comparison before/after `next(action)` is a
cheap and reliable "did project content change?" signal — no action allowlist
needs to be maintained as new actions are added.

### State

Add to `FileState` ([file_state.dart](lib/redux/state/file_state.dart)):

```dart
final bool hasUnsavedChanges; // default + initial() = false
```

(Include in `copyWith` as usual.)

### Actions

Add to `sync_actions.dart`:

```dart
class SetHasUnsavedChanges {
  final bool value;
  SetHasUnsavedChanges(this.value);
}
```

### Reducer

In `fileStateReducer` ([file_state_reducer.dart](lib/redux/reducers/file_state_reducer.dart)):

- `SetHasUnsavedChanges` → `state.copyWith(hasUnsavedChanges: a.value)`
- `NewProject` → additionally set `hasUnsavedChanges: false` (clean baseline)
- `OpenProject` → additionally set `hasUnsavedChanges: false` (clean baseline)
- `SetProjectFileMetadata` → additionally set `hasUnsavedChanges: false`.
  This action is only dispatched by `saveProjectFile` after
  `serializeProjectFile` succeeds
  ([file_actions.dart:174](lib/redux/actions/file_actions.dart#L174)), so it
  is the natural "save completed" clean point.

### Middleware

New file `lib/redux/middleware/unsaved_changes_middleware.dart`:

```dart
void unsavedChangesMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  final before = store.state.fixtureState;
  next(action);
  final after = store.state.fixtureState;

  if (identical(before, after)) return;

  // These actions replace fixture state wholesale and establish a clean
  // baseline; the reducer already resets the flag for them.
  if (action is NewProject || action is OpenProject) return;

  if (!store.state.fileState.hasUnsavedChanges) {
    store.dispatch(SetHasUnsavedChanges(true));
  }
}
```

Register on `appStore` **only** ([app_store.dart](lib/redux/app_store.dart)):

```dart
middleware: [thunkMiddleware, unsavedChangesMiddleware],
```

`diffAppStore` must *not* get this middleware — the diffing store loads
comparison files into `fixtureState` and should never dirty the project.

### Notes / known gaps (acceptable for v1)

- Actions handled by a sub-reducer that produce a value-equal but new
  `FixtureState` instance will set the flag even if nothing meaningfully
  changed. False positives are safe (worst case: one unnecessary prompt).
- Edits that live outside `fixtureState` are not tracked — notably
  `UpdateProjectName` / `SetLastUsedExportDirectory`, which mutate
  `fileState.projectMetadata`. If we want these covered, the middleware can
  additionally compare `identical(before.fileState.projectMetadata,
  after.fileState.projectMetadata)` with `SetProjectFileMetadata`,
  `SetProjectFilePath`, `NewProject`, and `OpenProject` excluded. Recommend
  deferring; flag it in the PR.
- Existing quirk, out of scope: `startNewProject` dispatches the async
  `saveProjectFile` thunk and immediately dispatches `NewProject` without
  awaiting it ([file_actions.dart:100-110](lib/redux/actions/file_actions.dart#L100-L110)).
  The dirty flag makes this pre-existing race more visible; worth fixing
  separately.

---

## 2. `window_manager` integration

### Dependency

```
flutter pub add window_manager
```

(v0.5.x at time of writing; supports Windows, macOS, Linux.)

### Initialization — [main.dart](lib/main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
  }

  runApp(const MyApp());
}
```

Keep `preventClose` **always true** on desktop rather than toggling it in
response to the dirty flag. Toggling invites races (a state change between the
toggle and the close event); with it always on, the decision is made
synchronously inside the close handler against current store state.

### Close listener widget

New widget `lib/window_close_observer.dart` — a `StatefulWidget` whose state
mixes in `WindowListener`. Mount it *inside* `ShadcnApp` so a `Navigator` is
above it; the existing global `navigatorKey`
([global_keys.dart](lib/global_keys.dart), already wired into `ShadcnApp` in
[home_scaffold.dart:20](lib/home_scaffold.dart#L20)) provides the dialog
context. Simplest placement: wrap `HomeContainer` (or whatever `ShadcnApp`'s
`home` is) in `WindowCloseObserver(child: ...)`.

```dart
class _WindowCloseObserverState extends State<WindowCloseObserver>
    with WindowListener {
  bool _isHandlingClose = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_isHandlingClose) return; // Re-entrancy guard (repeated Alt+F4 etc.)
    if (!await windowManager.isPreventClose()) return;

    if (!appStore.state.fileState.hasUnsavedChanges) {
      await windowManager.destroy();
      return;
    }

    _isHandlingClose = true;
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        await windowManager.destroy();
        return;
      }

      final result = await showSaveBeforeClosingDialog(context: context);

      switch (result) {
        case CloseRequestResult.cancel || null:
          return;
        case CloseRequestResult.discard:
          await windowManager.destroy();
        case CloseRequestResult.save:
          final saved = await saveProject(appStore, context, SaveType.save);
          if (saved) {
            await windowManager.destroy();
          }
          // Save failed or Save As was cancelled: abort the close and leave
          // the app running. saveProject already surfaced an error toast.
      }
    } finally {
      _isHandlingClose = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

`windowManager.destroy()` (not `close()`) is the "really close now" call —
`close()` would re-trigger `onWindowClose` because preventClose is on.

### Save flow refactor (prerequisite for "Save and close")

The close handler needs to know whether the save actually completed —
`saveProjectFile` is a `ThunkAction` and its outcome can't be awaited through
`store.dispatch`. Refactor [file_actions.dart](lib/redux/actions/file_actions.dart):

- Extract the body of `saveProjectFile` into
  `Future<bool> saveProject(Store<AppState> store, BuildContext context, SaveType saveType)`
  returning `true` only after `serializeProjectFile` succeeds and the
  metadata/path actions are dispatched. Return `false` when the Save As picker
  is cancelled or serialization throws.
- `saveProjectFile` becomes a thin thunk wrapper:
  `(store) async => saveProject(store, context, saveType);` — no call-site
  changes elsewhere.

---

## 3. Save-changes dialog

Three outcomes are required (Save / Discard / Cancel), so the existing
two-button `showGenericDialog` doesn't fit. Add
`lib/generic_dialog/show_save_before_closing_dialog.dart` following the same
shadcn `AlertDialog` pattern
([show_generic_dialog.dart](lib/generic_dialog/show_generic_dialog.dart)):

```dart
enum CloseRequestResult { save, discard, cancel }

Future<CloseRequestResult?> showSaveBeforeClosingDialog({
  required BuildContext context,
}) {
  return showDialog<CloseRequestResult>(
    context: context,
    builder: (innerContext) => AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text(
        'Would you like to save the changes to your project before closing?',
      ),
      actions: [
        Button(
          style: const ButtonStyle.text(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.cancel),
          child: const Text('Cancel'),
        ),
        Button(
          style: const ButtonStyle.destructive(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.discard),
          child: const Text('Discard'),
        ),
        Button(
          style: const ButtonStyle.primary(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.save),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
```

Barrier dismiss / Escape returns `null` — treated as Cancel.

Dialog title is explicit text (per project accessibility rule for dialogs).

**Follow-up opportunity (not in scope):** `FileScreen`'s New/Open flows use
the two-button Save/Discard dialog with no explicit Cancel
([file_screen.dart:110-120](lib/screens/file/file_screen.dart#L110-L120)).
Once this three-way dialog exists, those flows could adopt it — and could also
start consulting `hasUnsavedChanges` to skip the prompt entirely when the
project is clean.

---

## 4. macOS support

### 4a. Create the macOS runner

The repo currently has **no `macos/` directory** (only `windows/` and `web/`).
First step, run on a Mac:

```
flutter create --platforms=macos .
```

Then commit the generated `macos/` folder.

### 4b. AppDelegate.swift tweaks

Two behaviors are needed, both in `macos/Runner/AppDelegate.swift`:

1. **Terminate after last window closes.** The current Flutter template
   already generates `applicationShouldTerminateAfterLastWindowClosed`
   returning `true` — verify it's present after `flutter create`.
2. **Route Quit (⌘Q / menu / Dock) through the window-close path.** Without
   this, quitting terminates the process directly and `onWindowClose` never
   fires, bypassing the unsaved-changes prompt. Override
   `applicationShouldTerminate` to convert quit into a window close, which
   `window_manager`'s preventClose hook then intercepts:

```swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  // Route Quit through the window-close path so window_manager's
  // preventClose hook (and the Dart onWindowClose handler) can intercept it.
  override func applicationShouldTerminate(
    _ sender: NSApplication
  ) -> NSApplication.TerminateReply {
    mainFlutterWindow?.performClose(nil)
    return .terminateCancel
  }

  override func applicationSupportsSecureRestorableState(
    _ app: NSApplication
  ) -> Bool {
    return true
  }
}
```

End-to-end flow on macOS: ⌘Q → `applicationShouldTerminate` → `performClose`
→ window_manager blocks the close and emits `onWindowClose` → Dart shows the
dialog → on Save/Discard, `windowManager.destroy()` closes the window →
`applicationShouldTerminateAfterLastWindowClosed` (true) terminates the app.
On Cancel, `.terminateCancel` has already kept the app alive.

> Verify the exact `applicationShouldTerminate` recipe against the plugin's
> current docs (leanflutter.dev → window_manager → "Confirm before closing")
> when implementing — the docs site wasn't reachable while writing this spec,
> so the snippet above is from the pattern the plugin has historically
> documented.

### 4c. Protecting the manual tweak

Recorded in Claude's persistent memory (see
`memory/macos-appdelegate-window-manager.md` note): `AppDelegate.swift` is a
version-controlled file, so once committed, **`flutter clean` will not touch
it** — `flutter clean` only deletes `build/` and `.dart_tool/`. The command
that *can* regenerate platform files is `flutter create .` (e.g. when adding
another platform). Mitigations:

- Commit the modified `AppDelegate.swift` and treat any diff to it in
  `git status` after running `flutter create` as a red flag.
- Optional belt-and-braces: a CI/pre-build check that greps
  `macos/Runner/AppDelegate.swift` for `applicationShouldTerminate` and fails
  the build if the override is missing.

---

## Implementation order

1. `FileState.hasUnsavedChanges` + `SetHasUnsavedChanges` action + reducer
   cases (`NewProject` / `OpenProject` / `SetProjectFileMetadata` clear it).
2. `unsavedChangesMiddleware` + register on `appStore`.
3. Extract `saveProject(...) → Future<bool>` from `saveProjectFile`.
4. Add `window_manager` dependency; `main()` init + `setPreventClose(true)`.
5. `showSaveBeforeClosingDialog` + `CloseRequestResult`.
6. `WindowCloseObserver` widget wired into the tree; verify on Windows.
7. macOS: `flutter create --platforms=macos .`, AppDelegate overrides, verify
   on a Mac.

## Test plan

**Unit (Redux):**
- Dispatching any fixture-mutating action (e.g. an `UpdateFixture`-style sync
  action) sets `hasUnsavedChanges`.
- Dispatching a non-fixture action (e.g. `SetIsValidatingExportData`) does not.
- `NewProject`, `OpenProject`, `SetProjectFileMetadata` each clear the flag.
- Flag-setting dispatch happens at most once while dirty (no action spam).

**Manual, Windows:** titlebar ✕, Alt+F4 — each of: clean project closes
silently; dirty + Cancel keeps app open; dirty + Discard closes without
writing; dirty + Save writes file then closes; dirty + Save on untitled
project opens Save As, and cancelling Save As aborts the close.

**Manual, macOS:** same matrix via titlebar red button, ⌘Q, menu bar Quit,
and Dock → Quit; confirm the process terminates after the window closes in
every close path.
