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
              onSelected: (key) =>
                  onTabSelected((key as ValueKey<int>).value),
              selectedKey: ValueKey(selectedTab),
              alignment: NavigationBarAlignment.end,
              children: const [
                NavigationItem(key: ValueKey(0), child: Text('Fixtures')),
                NavigationItem(key: ValueKey(1), child: Text('Patch')),
                NavigationItem(key: ValueKey(2), child: Text('Looms')),
                NavigationItem(key: ValueKey(3), child: Text('Hoists')),
              ],
            ),
          ),
        ],
      ),
    );
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
