import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:sidekick/home_scaffold.dart';

import 'package:sidekick/redux/app_store.dart';

import 'package:sidekick/redux/state/app_state.dart';

void main() {
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
