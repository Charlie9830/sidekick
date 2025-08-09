import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/widgets/toolbar.dart';

class DiffingToolbar extends StatelessWidget {
  final String comparisonFilePath;
  final String comparisonFileInitialDirectory;
  final void Function(String path) onFileSelectedForCompare;

  final TabController tabController;
  const DiffingToolbar({
    super.key,
    required this.tabController,
    required this.comparisonFilePath,
    required this.comparisonFileInitialDirectory,
    required this.onFileSelectedForCompare,
  });

  @override
  Widget build(BuildContext context) {
    final tabLabelTextStyle = Theme.of(context).textTheme.bodySmall;
    const tabIconSize = 16.0;

    return Toolbar(
        height: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileSelectButton(
              path: comparisonFilePath,
              onFileSelectPressed: _handleSelectFileForComparePressed,
              hintText: 'Select file to compare with..',
              dropTargetName: 'Drop Phase Project here',
              onFileDropped: onFileSelectedForCompare,
            ),
            TabBar(
              dividerHeight: 0,
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
                  icon: const Icon(Icons.cable, size: tabIconSize),
                  child: Text('Looms', style: tabLabelTextStyle),
                ),
                Tab(
                    icon: const Icon(Icons.construction, size: tabIconSize),
                    child: Text('Hoists', style: tabLabelTextStyle))
              ],
            ),
          ],
        ));
  }

  void _handleSelectFileForComparePressed() async {
    final result = await openFile(
      confirmButtonText: 'Select',
      acceptedTypeGroups: kProjectFileTypes,
      initialDirectory: comparisonFileInitialDirectory,
    );

    if (result != null) {
      onFileSelectedForCompare(result.path);
    }
  }
}
