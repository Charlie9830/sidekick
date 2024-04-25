import 'package:flutter/material.dart';
import 'package:sidekick/containers/home_container.dart';
import 'package:sidekick/routes.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sidekick',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigoAccent, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        initialRoute: Routes.home,
        routes: {Routes.home: (context) => const HomeContainer()});
  }
}
