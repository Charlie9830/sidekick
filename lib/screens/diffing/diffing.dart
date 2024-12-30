import 'package:flutter/material.dart';
import 'package:sidekick/containers/looms_diffing_container.dart';
import 'package:sidekick/screens/diffing/diffing_toolbar.dart';
import 'package:sidekick/screens/diffing/loom_diffing.dart';
import 'package:sidekick/view_models/diffing_view_model.dart';

class Diffing extends StatefulWidget {
  final DiffingViewModel vm;
  const Diffing({
    super.key,
    required this.vm,
  });

  @override
  State<Diffing> createState() => _DiffingState();
}

class _DiffingState extends State<Diffing> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(seconds: 0),
      initialIndex: widget.vm.selectedTab,
    );

    _tabController.addListener(() {
      if (widget.vm.selectedTab != _tabController.index) {
        widget.vm.onDiffingTabChanged(_tabController.index);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiffingToolbar(
          tabController: _tabController,
        ),
        Expanded(
            child: TabBarView(
          controller: _tabController,
          children: const [
            Text('Fixtures'),
            Text('Power Patch'),
            Text('Data Patch'),
            LoomsDiffingContainer(),
          ],
        ))
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
