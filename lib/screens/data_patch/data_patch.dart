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
            ElevatedButton.icon(
                icon: const Icon(Icons.cable),
                onPressed: vm.onGeneratePatchPressed,
                label: const Text('Patch')),
            const VerticalDivider(),
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
      DataMultiRow multiRow => _buildMultiRow(multiRow, context),
      SingleDataPatchRow patchRow => DataPatchListItem(
          key: Key(patchRow.patch.uid),
          patch: patchRow.patch,
        ),
      _ => const Text("Error"),
    };
  }

  Widget _buildMultiRow(DataMultiRow row, BuildContext context) {
    return Card(
      key: Key(row.multi.uid),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings_input_svideo, color: Colors.blue),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    row.multi.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            ...row.patches.map((patch) => DataPatchListItem(patch: patch))
          ],
        ),
      ),
    );
  }
}
