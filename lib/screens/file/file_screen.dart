import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/screens/file/drop_zone.dart';
import 'package:sidekick/titled_card.dart';
import 'package:sidekick/view_models/file_view_model.dart';
import 'package:path/path.dart' as p;

class FileScreen extends StatelessWidget {
  final FileViewModel vm;
  const FileScreen({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropZone(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitledCard(
                  title: 'Patch',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                          message: p.canonicalize(vm.importFilePath),
                          child: Text(p.basename(vm.importFilePath))),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _handleChooseButtonPressed(context),
                        child: const Text('Choose'),
                      ),
                    ],
                  )),
              TitledCard(
                  title: 'Project',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      switch (vm.projectFilePath) {
                        "" => Text('Untitled Project'),
                        _ => Tooltip(
                            message: p.canonicalize(vm.projectFilePath),
                            child: Text(p.basename(vm.projectFilePath))),
                      },
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => throw "Not Implemented Yet ya Donkey.",
                        child: const Text('New'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _handleOpenProjectButtonPressed(context),
                        child: const Text('Open'),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () =>
                            _handleSaveProjectButtonPressed(context),
                        child: const Text('Save'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _handleSaveProjectAsButtonPressed(context),
                        child: const Text('Save as'),
                      )
                    ],
                  ))
            ],
          ),
        ),
        draggingBuilder: (_) =>
            const Center(child: Icon(Icons.download, size: 48)),
        onDragDrop: (files) {
          if (files.length == 1) {
            vm.onFileSelected(files.first.path);
          }
        });
  }

  void _handleOpenProjectButtonPressed(BuildContext context) async {
    final saveCurrentFileDialogResult = await showGenericDialog(
      context: context,
      title: 'Open Project',
      message: 'Would you like to Save your current project first?',
      affirmativeText: 'Save',
      declineText: 'Discard',
    );

    if (saveCurrentFileDialogResult == null) {
      return;
    }

    final selectedFilePath =
        await openFile(acceptedTypeGroups: kProjectFileTypes);

    if (context.mounted) {
      if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
        vm.onOpenProjectButtonPressed(
            context, saveCurrentFileDialogResult, selectedFilePath.path);
      }
    }
  }

  void _handleSaveProjectButtonPressed(BuildContext context) async {
    vm.onSaveProjectButtonPressed(context, SaveType.save);
  }

  void _handleSaveProjectAsButtonPressed(BuildContext context) async {
    vm.onSaveProjectButtonPressed(context, SaveType.saveAs);
  }

  void _handleChooseButtonPressed(BuildContext context) async {
    final selectedFilePath =
        await openFile(acceptedTypeGroups: kExcelFileTypes);

    if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
      vm.onFileSelected(selectedFilePath.path);
    }
  }
}
