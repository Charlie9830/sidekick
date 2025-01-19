import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/card_subtitle.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/screens/file/file_selector_button.dart';
import 'package:sidekick/view_models/import_view_model.dart';
import 'package:path/path.dart' as path;
import 'package:sidekick/widgets/property_field.dart';

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
          const SizedBox(height: 32),
          SizedBox(
              width: 200,
              child: DropdownButton<String>(
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: vm.sheetNames.isEmpty
                    ? null
                    : (value) => vm.onSettingsChanged(
                        vm.settings.copyWith(patchDataSourceSheetName: value)),
                items: vm.sheetNames
                    .map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                hint: const Text('Select Sheet...'),
                isExpanded: true,
                value: vm.settings.patchDataSourceSheetName.isEmpty
                    ? null
                    : vm.settings.patchDataSourceSheetName,
              )),
          const SizedBox(height: 16),
          CheckboxListTile(
              title: const Text("Merge with Existing"),
              value: vm.settings.mergeWithExisting,
              onChanged: (value) => vm.onSettingsChanged(
                  vm.settings.copyWith(mergeWithExisting: value))),
          if (vm.settings.mergeWithExisting)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Import Type'),
                    DropdownButton<ImportType>(
                        value: vm.settings.type,
                        items: const [
                          DropdownMenuItem(
                            value: ImportType.addNewRecords,
                            child: Text('Add new Fixtures'),
                          ),
                          DropdownMenuItem(
                            value: ImportType.onlyUpdateExisting,
                            child: Text('Only update existing Fixtures'),
                          )
                        ],
                        onChanged: (value) => vm.onSettingsChanged(
                            vm.settings.copyWith(type: value)))
                  ],
                ),
                const SizedBox(height: 32),
                Text('Overwrite Existing',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                CheckboxListTile(
                    title: const Text('Sequence Number'),
                    value: vm.settings.overwriteSeqNumber,
                    onChanged: (value) => vm.onSettingsChanged(
                        vm.settings.copyWith(overwriteSeqNumber: value))),
                CheckboxListTile(
                    title: const Text('Fixture Type'),
                    value: vm.settings.overwriteType,
                    onChanged: (value) => vm.onSettingsChanged(
                        vm.settings.copyWith(overwriteType: value))),
                CheckboxListTile(
                    title: const Text('Location'),
                    value: vm.settings.overwriteLocation,
                    onChanged: (value) => vm.onSettingsChanged(
                        vm.settings.copyWith(overwriteLocation: value))),
                CheckboxListTile(
                    title: const Text('Address'),
                    value: vm.settings.overwriteAddress,
                    onChanged: (value) => vm.onSettingsChanged(
                        vm.settings.copyWith(overwriteAddress: value))),
              ],
            ),
          const SizedBox(height: 16),
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
