import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/generic_dialog/show_save_before_closing_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/redux/actions/file_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/window_manager_support.dart';
import 'package:window_manager/window_manager.dart';

/// Intercepts window close requests to prompt about unsaved changes.
///
/// Must be mounted inside `ShadcnApp` so that [navigatorKey] has a
/// [Navigator] to show the dialog against. Relies on `setPreventClose(true)`
/// having been set during startup; without it the window closes before this
/// handler is consulted.
class WindowCloseObserver extends StatefulWidget {
  final Widget child;

  const WindowCloseObserver({super.key, required this.child});

  @override
  State<WindowCloseObserver> createState() => _WindowCloseObserverState();
}

class _WindowCloseObserverState extends State<WindowCloseObserver>
    with WindowListener {
  /// Guards against a second prompt while the first is still open, e.g. from
  /// repeated Alt+F4 or ⌘Q presses.
  bool _isHandlingClose = false;

  @override
  void initState() {
    super.initState();

    if (supportsWindowManager) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (supportsWindowManager) {
      windowManager.removeListener(this);
    }

    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_isHandlingClose) {
      return;
    }

    if (!await windowManager.isPreventClose()) {
      return;
    }

    if (!appStore.state.fileState.hasUnsavedChanges) {
      await windowManager.destroy();
      return;
    }

    _isHandlingClose = true;
    try {
      final dialogContext = navigatorKey.currentContext;

      if (dialogContext == null || !dialogContext.mounted) {
        /// Workaround for
        /// https://github.com/leanflutter/window_manager/issues/478
        await windowManager.setPreventClose(false);
        await windowManager.close();
        return;
      }

      final result = await showSaveBeforeClosingDialog(context: dialogContext);

      switch (result) {
        case CloseRequestResult.cancel:
          return;
        case CloseRequestResult.discard:

          /// Workaround for
          /// https://github.com/leanflutter/window_manager/issues/478
          await windowManager.setPreventClose(false);
          await windowManager.close();
        case CloseRequestResult.save:
          final saveContext = navigatorKey.currentContext;

          if (saveContext == null || !saveContext.mounted) {
            return;
          }

          if (await saveProject(appStore, saveContext, SaveType.save)) {
            /// Workaround for
            /// https://github.com/leanflutter/window_manager/issues/478
            await windowManager.setPreventClose(false);
            await windowManager.close();
          }
        // Save failed or 'Save As' was cancelled, so abort the close and leave
        // the app running. saveProject has already surfaced any error.
      }
    } finally {
      _isHandlingClose = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
