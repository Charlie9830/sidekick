import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/home_container.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/theme/sidekick_color_scheme.dart';
import 'package:sidekick/typography.dart';
import 'package:sidekick/window_close_observer.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      theme: const ThemeData.dark(
        typography: appTypography,
        colorScheme: sidekickDarkColorScheme,
        platform: TargetPlatform.windows,
      ),
      scaling: AdaptiveScaling.desktop,
      title: "It's just a Phase!",
      navigatorKey: navigatorKey,
      // Mounted inside ShadcnApp so the observer has a Navigator above it to
      // show the unsaved-changes dialog against.
      home: const WindowCloseObserver(child: HomeContainer()),
    );
  }
}
