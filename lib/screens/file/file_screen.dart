import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/containers/import_container.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/screens/file/file_selector_button.dart';
import 'package:sidekick/titled_card.dart';
import 'package:sidekick/view_models/file_view_model.dart';
import 'package:path/path.dart' as p;

class FileScreen extends StatelessWidget {
  final FileViewModel vm;
  const FileScreen({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitledCard(
                title: 'Project',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    switch (vm.projectFilePath) {
                      "" => const Text('Untitled Project'),
                      _ => Tooltip(
                          message: p.canonicalize(vm.projectFilePath),
                          child: Text(p.basename(vm.projectFilePath))),
                    },
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _handleNewProjectButtonPressed(context),
                      child: const Text('New'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _handleOpenProjectButtonPressed(context),
                      child: const Text('Open'),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => _handleSaveProjectButtonPressed(context),
                      child: const Text('Save'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          _handleSaveProjectAsButtonPressed(context),
                      child: const Text('Save as'),
                    )
                  ],
                )),
            const TitledCard(
              title: "Import",
              child: ImportContainer(),
            ),
            TitledCard(
                title: "Other Data Sources",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fixture Type Database',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(width: 16),
                        switch (vm.isFixtureTypeDatabasePathValid) {
                          true => const Icon(Icons.check, color: Colors.green),
                          false => const Icon(Icons.clear, color: Colors.red),
                        }
                      ],
                    ),
                    const SizedBox(height: 16),
                    FileSelectorButton(
                      path: vm.fixtureTypeDatabasePath,
                      onPressed: () =>
                          _handleChooseFixtureTypeDatabaseButtonPressed(
                        context,
                      ),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  void _handleNewProjectButtonPressed(BuildContext context) async {
    final saveCurrentFileDialogResult =
        await _showSaveChangesDialog(title: 'New Project', context: context);

    if (saveCurrentFileDialogResult == null) {
      return;
    }

    vm.onNewProjectButtonPressed(saveCurrentFileDialogResult);
  }

  void _handleOpenProjectButtonPressed(BuildContext context) async {
    final saveCurrentFileDialogResult =
        await _showSaveChangesDialog(title: 'Open Project', context: context);

    if (saveCurrentFileDialogResult == null) {
      return;
    }

    final selectedFilePath =
        await openFile(acceptedTypeGroups: kProjectFileTypes);

    if (context.mounted) {
      if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
        vm.onOpenProjectButtonPressed(
            saveCurrentFileDialogResult, selectedFilePath.path);
      }
    }
  }

  Future<bool?> _showSaveChangesDialog(
      {required BuildContext context, required String title}) async {
    return await showGenericDialog(
      context: context,
      title: title,
      message:
          'Would you like to save the changes to your current project first?',
      affirmativeText: 'Save',
      declineText: 'Discard',
    );
  }

  void _handleSaveProjectButtonPressed(BuildContext context) async {
    vm.onSaveProjectButtonPressed(SaveType.save);
  }

  void _handleSaveProjectAsButtonPressed(BuildContext context) async {
    vm.onSaveProjectButtonPressed(SaveType.saveAs);
  }

  void _handleChooseFixtureTypeDatabaseButtonPressed(
      BuildContext context) async {
    final selectedFilePath =
        await openFile(acceptedTypeGroups: kExcelFileTypes);

    if (context.mounted) {
      if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
        vm.onFixtureTypeDatabaseFileSelected(selectedFilePath.path);
      }
    }
  }
}
