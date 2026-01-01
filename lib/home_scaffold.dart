import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/home_container.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/typography.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      theme: const ThemeData.dark(
        typography: appTypography,
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
