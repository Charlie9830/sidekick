import 'package:file_selector/file_selector.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
              Text(sourceFileClass, style: Theme.of(context).typography.medium),
              const Divider(height: 8),
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
                      style: Theme.of(context).typography.medium),
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
                      style: Theme.of(context).typography.medium),
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
                style: Theme.of(context).typography.small),
            SizedBox(
              width: 224,
              child: Select<MvrLocationDataSource>(
                value: settings.mvrLocationDataSource,
                onChanged: (value) => onSettingsUpdated(
                    settings.copyWith(mvrLocationDataSource: value)),
                popup: const SelectPopup<MvrLocationDataSource>(
                    items: SelectItemList(children: [
                  SelectItemButton(
                    value: MvrLocationDataSource.layers,
                    child: Text('Layers'),
                  ),
                  SelectItemButton(
                    value: MvrLocationDataSource.grouping,
                    child: Text('Grouping'),
                  ),
                  SelectItemButton(
                    value: MvrLocationDataSource.classes,
                    child: Text('Classes'),
                  ),
                  SelectItemButton(
                    value: MvrLocationDataSource.position,
                    child: Text('Position Attribute'),
                  ),
                ])),
                itemBuilder: (context, value) => Text(switch (value) {
                  MvrLocationDataSource.layers => 'Layers',
                  MvrLocationDataSource.classes => 'Classes',
                  MvrLocationDataSource.position => 'Position',
                  MvrLocationDataSource.grouping => 'Grouping',
                }),
              ),
            ),
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
      width: 364,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Patch Type', style: Theme.of(context).typography.medium),
              const Divider(height: 16.0),
              RadioGroup<PatchSource>(
                  value: settings.source,
                  onChanged: (newValue) =>
                      onSettingsUpdated(settings.copyWith(source: newValue)),
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RadioListTile(
                          value: PatchSource.mvr,
                          title: 'MVR File',
                          subtitle: 'My Virtual Rig file.',
                        ),
                        SizedBox(height: 8),
                        _RadioListTile(
                          value: PatchSource.grandMA2XML,
                          title: 'GrandMA2 Fixture Layers',
                          subtitle: 'XML export of GrandMA2 Fixture Layers',
                        ),
                      ])),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioListTile<T> extends StatelessWidget {
  final T value;
  final String title;
  final String? subtitle;
  const _RadioListTile(
      {super.key, required this.title, this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioItem<T>(
          value: value,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (subtitle != null)
                Text(subtitle!,
                    style: Theme.of(context)
                        .typography
                        .xSmall
                        .copyWith(color: Colors.gray))
            ],
          )),
    );
  }
}
