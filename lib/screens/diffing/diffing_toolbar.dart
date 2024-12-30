import 'package:flutter/material.dart';
import 'package:sidekick/widgets/toolbar.dart';

class DiffingToolbar extends StatelessWidget {
  final TabController tabController;
  const DiffingToolbar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final tabLabelTextStyle = Theme.of(context).textTheme.bodySmall;
    const tabIconSize = 16.0;

    return Toolbar(
        child: TabBar(
          
      controller: tabController,
      
      tabs: [
        Tab(
          icon: const Icon(Icons.lightbulb, size: tabIconSize),
          child: Text('Fixtures', style: tabLabelTextStyle),
        ),
        Tab(
          icon: const Icon(Icons.electric_bolt, size: tabIconSize),
          child: Text('Patch', style: tabLabelTextStyle),
        ),
        Tab(
            icon: const Icon(Icons.settings_input_svideo, size: tabIconSize),
            child: Text('Patch', style: tabLabelTextStyle)),
        Tab(
          icon: const Icon(Icons.cable, size: tabIconSize),
          child: Text('Looms', style: tabLabelTextStyle),
        ),
      ],
    ));
  }
}
