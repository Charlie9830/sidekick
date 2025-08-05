import 'package:flutter/material.dart';
import 'package:sidekick/containers/home_container.dart';
import 'package:sidekick/routes.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "It's just a Phase!",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'OpenSans',
          textTheme: const TextTheme(
              titleMedium: TextStyle(fontWeight: FontWeight.w500)),
          colorScheme: ColorScheme.fromSeed(
              dynamicSchemeVariant: DynamicSchemeVariant.content,
              contrastLevel: 0.2,
              seedColor: Colors.blue.shade700,
              brightness: Brightness.dark),
          useMaterial3: true,
          visualDensity: VisualDensity.compact,
          dropdownMenuTheme: const DropdownMenuThemeData(
            textStyle: TextStyle(
              fontSize: 14,
            ),
            inputDecorationTheme: InputDecorationTheme(
              constraints: BoxConstraints(maxHeight: 36),
              contentPadding: EdgeInsets.only(left: 8),
              isDense: true,
              filled: false,
            ),
          ),
        ),
        initialRoute: Routes.home,
        routes: {Routes.home: (context) => const HomeContainer()});
  }
}
