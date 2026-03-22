import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/card_subtitle.dart';
import 'package:sidekick/redux/models/export_error_model.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/titled_card.dart';

import 'package:sidekick/view_models/export_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class Export extends StatelessWidget {
  final ExportViewModel vm;
  const Export({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                            .typography
                            .small
                            .copyWith(color: Colors.gray)),
                    _ => Text(vm.lastUsedExportDirectory),
                  },
                  const SizedBox(height: 16),
                  OutlineButton(
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
                  ShadListItem(
                      trailing: Checkbox(
                        onChanged: (value) => vm.onOpenAfterExportChanged(
                            value == CheckboxState.checked),
                        state: vm.openAfterExport
                            ? CheckboxState.checked
                            : CheckboxState.unchecked,
                      ),
                      title: const Text('Open after export')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PrimaryButton(
                          onPressed: vm.onExportButtonPressed,
                          child: const Text('Export'))
                    ],
                  )
                ],
              ),
            )),
        TitledCard(
          title: 'Errors',
          child: SizedBox(
            width: 600,
            child: _ExportErrors(
              errors: vm.exportErrors,
              isValidating: vm.isValidating,
              onRefreshPressed: vm.onValidateButtonPressed,
            ),
          ),
        )
      ]),
    );
  }
}

class _ExportErrors extends StatelessWidget {
  final List<ExportErrorModel> errors;
  final void Function() onRefreshPressed;
  final bool isValidating;

  const _ExportErrors({
    super.key,
    required this.errors,
    required this.onRefreshPressed,
    required this.isValidating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.secondary(
          icon: isValidating
              ? const CircularProgressIndicator(size: 20)
              : const Icon(Icons.refresh),
          onPressed: isValidating ? null : onRefreshPressed,
        ),
        if (errors.isEmpty) const Text('No Errors'),
        if (errors.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) =>
                _ExportErrorItem(errorItem: errors[index]),
          ),
      ],
    );
  }
}

class _ExportErrorItem extends StatelessWidget {
  final ExportErrorModel errorItem;
  const _ExportErrorItem({super.key, required this.errorItem});

  @override
  Widget build(BuildContext context) {
    return ShadListItem(
        leading: switch (errorItem.level) {
          ExportErrorLevel.warning =>
            const Icon(Icons.error, color: Colors.amber),
          ExportErrorLevel.critical =>
            const Icon(Icons.error, color: Colors.red),
        },
        title: Text(errorItem.name),
        subtitle: Text(errorItem.message));
  }
}
