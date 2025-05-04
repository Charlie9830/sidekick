import 'package:flutter/material.dart';
import 'package:sidekick/screens/data_patch/data_patch_list_item.dart';
import 'package:sidekick/view_models/data_patch_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';
import 'package:sidekick/widgets/toolbar.dart';

class DataPatch extends StatelessWidget {
  final DataPatchViewModel vm;

  const DataPatch({
    Key? key,
    required this.vm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Toolbar(
            child: Row(
          children: [
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'If enabled, new data lines will be added when universe or sequence number breaks are detected',
              child: Row(
                children: [
                  Checkbox(
                    value: vm.honorDataSpans,
                    onChanged: (value) =>
                        vm.onHonorDataSpansChanged(value ?? true),
                  ),
                  const SizedBox(width: 8),
                  Text('Honor Data Spans',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.commit),
              onPressed: vm.onCommit,
              label: const Text('Commit'),
            ),
          ],
        )),
        Expanded(
          child: ListView.builder(
            itemCount: vm.rows.length,
            itemBuilder: (context, index) => _buildRow(context, vm.rows[index]),
          ),
        )
      ],
    );
  }

  Widget _buildRow(BuildContext context, DataPatchRow row) {
    return switch (row) {
      LocationRow locationRow => LocationHeaderRow(
          key: Key(locationRow.location.uid),
          location: locationRow.location,
        ),
      SingleDataPatchRow patchRow => DataPatchListItem(
          key: Key(patchRow.patch.uid),
          patch: patchRow.patch,
        ),
      _ => const Text("Error"),
    };
  }
}
