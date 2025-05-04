import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/card_subtitle.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/screens/file/file_selector_button.dart';
import 'package:sidekick/view_models/import_view_model.dart';

class Import extends StatelessWidget {
  final ImportViewModel vm;
  const Import({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardSubtitle('Source Path'),
          FileSelectorButton(
              path: vm.importFilePath,
              onPressed: () => _handleChooseButtonPressed(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => vm.onImportManagerButtonPressed(),
                  child: const Text('Start Import Manager')),
              const SizedBox(width: 16),
              FilledButton(
                  onPressed: () => vm.onImportButtonPressed(),
                  child: const Text('Import')),
            ],
          ),
        ],
      ),
    );
  }

  void _handleChooseButtonPressed(BuildContext context) async {
    final selectedFilePath =
        await openFile(acceptedTypeGroups: kExcelFileTypes);

    if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
      vm.onFileSelected(selectedFilePath.path);
    }
  }
}
