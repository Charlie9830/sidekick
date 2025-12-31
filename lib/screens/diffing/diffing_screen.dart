import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/diffing/diffing_toolbar.dart';
import 'package:sidekick/screens/diffing/fixture_diffing.dart';
import 'package:sidekick/screens/diffing/hoist_diffing.dart';
import 'package:sidekick/screens/diffing/loom_diffing.dart';
import 'package:sidekick/screens/diffing/patch_diffing.dart';
import 'package:sidekick/view_models/diffing_screen_view_model.dart';

class DiffingScreen extends StatefulWidget {
  final DiffingScreenViewModel viewModel;
  const DiffingScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<DiffingScreen> createState() => _DiffingScreenState();
}

class _DiffingScreenState extends State<DiffingScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiffingToolbar(
          comparisonFileInitialDirectory: widget.viewModel.initialDirectory,
          comparisonFilePath: widget.viewModel.comparisonFilePath,
          onFileSelectedForCompare: widget.viewModel.onFileSelectedForCompare,
          onTabSelected: widget.viewModel.onTabSelected,
          selectedTab: widget.viewModel.selectedTab,
        ),
        Expanded(
            child: switch (widget.viewModel.selectedTab) {
          0 => FixtureDiffing(itemVms: widget.viewModel.fixtureItemVms),
          1 => PatchDiffing(itemVms: widget.viewModel.patchItemVms),
          2 => LoomDiffing(
              itemVms: widget.viewModel.loomItemVms,
            ),
          3 => HoistDiffing(
              itemVms: widget.viewModel.hoistControllerVms,
            ),
          _ => throw UnimplementedError(
              'No Corresponding Screen for Diffing Tab Index ${widget.viewModel.selectedTab}'),
        })
      ],
    );
  }
}
