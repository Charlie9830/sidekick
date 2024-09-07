import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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
              SizedBox(
                height: 124,
                child: TitledCard(
                    title: 'Patch',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (vm.importFilePath.isNotEmpty)
                          Tooltip(
                              message: p.canonicalize(vm.importFilePath),
                              child: Text(p.basename(vm.importFilePath))),
                        ElevatedButton(
                          onPressed: () => _handleChooseButtonPressed(context),
                          child: const Text('Choose'),
                        ),
                      ],
                    )),
              ),
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

  void _handleChooseButtonPressed(BuildContext context) async {
    final selectedFilePath = await openFile(acceptedTypeGroups: [
      const XTypeGroup(
        label: "Excel Files (*.xls, *.xlsx)",
        extensions: ['xls', 'xlsx'],
      )
    ]);

    if (selectedFilePath != null && selectedFilePath.path.isNotEmpty) {
      vm.onFileSelected(selectedFilePath.path);
    }
  }
}
