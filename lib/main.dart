import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:sidekick/home_scaffold.dart';

import 'package:sidekick/redux/app_store.dart';

import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/window_manager_support.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supportsWindowManager) {
    await windowManager.ensureInitialized();

    // Left on permanently rather than toggled in response to the dirty flag.
    // Toggling invites a race between a state change and the close event; with
    // it always on, WindowCloseObserver decides synchronously against current
    // store state.
    await windowManager.setPreventClose(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: appStore,
      child: StoreProvider<DiffAppState>(
        store: diffAppStore,
        child: const HomeScaffold(),
      ),
    );
  }
}
