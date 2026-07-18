import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/widgets/toolbar.dart';

class DiffingToolbar extends StatelessWidget {
  final String comparisonFilePath;
  final String comparisonFileInitialDirectory;
  final void Function({String? path}) onSelectFileForCompareButtonPressed;
  final void Function(int index) onTabSelected;
  final int selectedTab;

  const DiffingToolbar({
    super.key,
    required this.comparisonFilePath,
    required this.comparisonFileInitialDirectory,
    required this.onSelectFileForCompareButtonPressed,
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
            onFileSelectPressed: () => onSelectFileForCompareButtonPressed(),
            hintText: 'Select file to compare with..',
            onFileDropped: (path) =>
                onSelectFileForCompareButtonPressed(path: path),
            dropTargetName: 'Drop Phase file here...',
          ),
          const Spacer(),
          Expanded(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              onSelected: (key) => onTabSelected((key as ValueKey<int>).value),
              selectedKey: ValueKey(selectedTab),
              alignment: NavigationBarAlignment.end,
              children: const [
                NavigationItem(key: ValueKey(0), child: Text('Fixtures')),
                NavigationItem(key: ValueKey(1), child: Text('Patch')),
                NavigationItem(key: ValueKey(2), child: Text('Looms')),
                NavigationItem(key: ValueKey(3), child: Text('Hoists')),
                NavigationItem(key: ValueKey(4), child: Text('Cabling')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
