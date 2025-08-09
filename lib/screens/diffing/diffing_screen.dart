import 'package:flutter/material.dart';
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
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(
        length: 4, vsync: this, animationDuration: const Duration());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiffingToolbar(
            tabController: _tabController,
            comparisonFileInitialDirectory: widget.viewModel.initialDirectory,
            comparisonFilePath: widget.viewModel.comparisonFilePath,
            onFileSelectedForCompare:
                widget.viewModel.onFileSelectedForCompare),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              FixtureDiffing(itemVms: widget.viewModel.fixtureItemVms),
              PatchDiffing(itemVms: widget.viewModel.patchItemVms),
              LoomDiffing(
                itemVms: widget.viewModel.loomItemVms,
              ),
              HoistDiffing(
                itemVms: widget.viewModel.hoistControllerVms,
              )
            ],
          ),
        )
      ],
    );
  }
}
