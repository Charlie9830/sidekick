import 'package:file_selector/file_selector.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/widgets/toolbar.dart';

class DiffingToolbar extends StatelessWidget {
  final String comparisonFilePath;
  final String comparisonFileInitialDirectory;
  final void Function(String path) onFileSelectedForCompare;
  final void Function(int index) onTabSelected;
  final int selectedTab;

  const DiffingToolbar({
    super.key,
    required this.comparisonFilePath,
    required this.comparisonFileInitialDirectory,
    required this.onFileSelectedForCompare,
    required this.onTabSelected,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    return Toolbar(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FileSelectButton(
              path: comparisonFilePath,
              onFileSelectPressed: _handleSelectFileForComparePressed,
              hintText: 'Select file to compare with..',
              dropTargetName: 'Drop Phase Project here',
              onFileDropped: onFileSelectedForCompare,
            ),
            const Spacer(),
            Expanded(
              child: NavigationBar(
                onSelected: (index) => onTabSelected(index),
                index: selectedTab,
                alignment: NavigationBarAlignment.end,
                expands: false,
                children: const [
                  NavigationItem(
                    child: Text('Fixtures'),
                  ),
                  NavigationItem(
                    child: Text('Patch'),
                  ),
                  NavigationItem(
                    child: Text('Looms'),
                  ),
                  NavigationItem(child: Text('Hoists')),
                ],
              ),
            )
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
