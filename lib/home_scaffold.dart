import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/home_container.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShadcnApp(
        theme: ThemeData.dark(
          typography: Typography.geist(),
          colorScheme: ColorSchemes.darkBlue,
          platform: TargetPlatform.windows,
        ),
        scaling: AdaptiveScaling.desktop,
        color: Colors.blue,
        title: "It's just a Phase!",
        home: HomeContainer());
  }
}
