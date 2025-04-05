import 'package:flutter/material.dart';
import 'package:sidekick/card_subtitle.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/titled_card.dart';

import 'package:sidekick/view_models/export_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class Export extends StatelessWidget {
  final ExportViewModel vm;
  const Export({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TitledCard(
          title: 'Export',
          child: SizedBox(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardSubtitle('Target Directory'),
                switch (vm.lastUsedExportDirectory) {
                  '' => Text('Choose an export location..',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Colors.grey)),
                  _ => Text(vm.lastUsedExportDirectory),
                },
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: vm.onChooseExportDirectoryButtonPressed,
                  child: const Text('Choose'),
                ),
                const SizedBox(height: 32),
                const CardSubtitle('Project Name'),
                SizedBox(
                  width: 200,
                  child: PropertyField(
                      hintText: 'Enter a project name',
                      value: vm.projectName,
                      onBlur: vm.onProjectNameChanged),
                ),
                const SizedBox(height: 32),
                const CardSubtitle('Settings'),
                CheckboxListTile(
                    value: vm.openAfterExport,
                    onChanged: vm.onOpenAfterExportChanged,
                    title: const Text('Open after export')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                        onPressed: vm.onExportButtonPressed,
                        child: const Text('Export'))
                  ],
                )
              ],
            ),
          ))
    ]);
  }
}
