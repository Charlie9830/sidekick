import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/home_container.dart';
import 'package:sidekick/global_keys.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      theme: const ThemeData.dark(
        typography: Typography.geist(),
        colorScheme: ColorSchemes.darkBlue,
        platform: TargetPlatform.windows,
      ),
      scaling: AdaptiveScaling.desktop,
      title: "It's just a Phase!",
      navigatorKey: navigatorKey,
      home: const HomeContainer(),
    );
  }
}
