import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/screens/file/import_module/file_valid_icon.dart';
import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:path/path.dart' as p;

enum PatchSource {
  grandMA2XML,
  mvr,
}

class SelectFileControl extends StatelessWidget {
  final String fixtureMappingFilePath;
  final String fixtureDatabaseFilePath;
  final String fixturePatchFilePath;

  final void Function(String path) onFixtureMappingFilePathChanged;
  final void Function(String path) onFixtureDatabaseFilePathChanged;
  final void Function(String path) onPatchFilePathChanged;

  final PatchImportSettings settings;

  final void Function(PatchImportSettings settings) onSettingsUpdated;

  final bool isFixtureMappingValid;
  final bool isFixtureDatabaseValid;

  const SelectFileControl({
    super.key,
    this.fixtureMappingFilePath = '',
    this.fixtureDatabaseFilePath = '',
    required this.fixturePatchFilePath,
    required this.onFixtureDatabaseFilePathChanged,
    required this.onFixtureMappingFilePathChanged,
    required this.settings,
    required this.onSettingsUpdated,
    required this.onPatchFilePathChanged,
    required this.isFixtureDatabaseValid,
    required this.isFixtureMappingValid,
  });

  @override
  Widget build(BuildContext context) {
    final sourceFileClass = switch (settings.source) {
      PatchSource.grandMA2XML => "GrandMA2 Fixture Layers",
      PatchSource.mvr => "MVR File",
    };

    return Row(
      children: [
        _buildSourceSelector(context),
        // Content
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sourceFileClass,
                  style: Theme.of(context).textTheme.titleSmall),
              const Divider(),
              FileSelectButton(
                path: fixturePatchFilePath,
                onFileSelectPressed: _handlePatchFileSelect,
                showOpenButton: false,
                dropTargetName: 'Drop $sourceFileClass here',
                onFileDropped: onPatchFilePathChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                  child: switch (settings.source) {
                PatchSource.grandMA2XML => const SizedBox(),
                PatchSource.mvr => _buildMvrImportSettings(context),
              }),
              const Divider(),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixture Mapping XML File.
                  Text('Fixture Name and Mode Mapping file',
                      style: Theme.of(context).textTheme.labelMedium),
                  Row(
                    spacing: 12,
                    children: [
                      FileValidIcon(
                        isValid: isFixtureMappingValid,
                      ),
                      FileSelectButton(
                        path: fixtureMappingFilePath,
                        onFileSelectPressed: _handleFixtureTypeMappingSelect,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fixture Database Spreadsheet.
                  Text('Fixture Database',
                      style: Theme.of(context).textTheme.labelMedium),
                  Row(
                    spacing: 12,
                    children: [
                      FileValidIcon(
                        isValid: isFixtureDatabaseValid,
                      ),
                      FileSelectButton(
                        path: fixtureDatabaseFilePath,
                        onFileSelectPressed: _handleFixtureDatabaseSelect,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ))
      ],
    );
  }

  Widget _buildMvrImportSettings(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 16,
          children: [
            Text('Fixture Location data source ie: Truss name',
                style: Theme.of(context).textTheme.labelMedium),
            DropdownMenu<MvrLocationDataSource>(
              enableFilter: false,
              enableSearch: false,
              initialSelection: settings.mvrLocationDataSource,
              onSelected: (value) => onSettingsUpdated(settings.copyWith(
                mvrLocationDataSource: value,
              )),
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                    value: MvrLocationDataSource.layers, label: 'Layers'),
                DropdownMenuEntry(
                    value: MvrLocationDataSource.grouping, label: 'Grouping'),
                DropdownMenuEntry(
                    value: MvrLocationDataSource.classes, label: 'Classes'),
                DropdownMenuEntry(
                    value: MvrLocationDataSource.position,
                    label: 'Position Attribute'),
              ],
            )
          ],
        ),
      ],
    );
  }

  void _handleFixtureTypeMappingSelect() async {
    final file = await openFile(
      confirmButtonText: "Select",
      acceptedTypeGroups: kXmlFileTypes,
      initialDirectory: fixtureMappingFilePath.isNotEmpty
          ? p.dirname(fixtureMappingFilePath)
          : null,
    );

    if (file == null) {
      return;
    }

    onFixtureMappingFilePathChanged(file.path);
  }

  void _handleFixtureDatabaseSelect() async {
    final file = await openFile(
      confirmButtonText: "Select",
      acceptedTypeGroups: kExcelFileTypes,
      initialDirectory: fixtureDatabaseFilePath.isNotEmpty
          ? p.dirname(fixtureDatabaseFilePath)
          : null,
    );

    if (file == null) {
      return;
    }

    onFixtureDatabaseFilePathChanged(file.path);
  }

  void _handlePatchFileSelect() async {
    final file = await openFile(
        confirmButtonText: 'Import',
        acceptedTypeGroups: switch (settings.source) {
          PatchSource.grandMA2XML => kXmlFileTypes,
          PatchSource.mvr => kMvrFileTypes,
        });

    if (file == null) {
      return;
    }

    onPatchFilePathChanged(file.path);
  }

  SizedBox _buildSourceSelector(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patch Type', style: Theme.of(context).textTheme.titleSmall),
              const Divider(),
              RadioListTile<PatchSource>(
                value: PatchSource.mvr,
                groupValue: settings.source,
                onChanged: (value) {
                  onSettingsUpdated(settings.copyWith(source: value));
                },
                title: const Text("MVR File"),
                subtitle: const Text('.mvr'),
              ),
              RadioListTile<PatchSource>(
                value: PatchSource.grandMA2XML,
                groupValue: settings.source,
                onChanged: (value) {
                  onSettingsUpdated(settings.copyWith(source: value));
                },
                title: const Text("GrandMA2 Fixture Layers"),
                subtitle: const Text('.xml'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
