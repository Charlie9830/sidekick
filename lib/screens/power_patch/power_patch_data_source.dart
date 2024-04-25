import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/screens/power_patch/power_patch_column_names.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class PowerPatchDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];

  PowerPatchDataSource({required List<PowerPatchModel> patches}) {
    _rows = _mapRows(patches);
  }

  List<DataGridRow> _mapRows(List<PowerPatchModel> patches) {
    return patches.mapIndexed((index, patch) {
      final multiOutlet = ((index + 1) / 6).ceil();
      final isFirstMultiOutletRow = _isNthRow(6, index);

      return DataGridRow(cells: [
        DataGridCell<String>(
          columnName: Columns.multiOutlet,
          value: isFirstMultiOutletRow ? multiOutlet.toString() : '-',
        ),
        DataGridCell<int>(columnName: Columns.patchNumber, value: index + 1),
        DataGridCell<String>(
            columnName: Columns.fixtureId,
            value: patch.fixtures.isEmpty
                ? ''
                : patch.fixtures.map((fixture) => fixture.fid).join(', ')),
        DataGridCell<String>(
            columnName: Columns.fixtureType,
            value:
                patch.fixtures.isEmpty ? '' : patch.fixtures.first.type.name),
        DataGridCell<double>(columnName: Columns.amps, value: patch.amps),
      ]);
    }).toList();
  }

  void update(List<PowerPatchModel> patches) {
    _rows.clear();
    _rows.addAll(_mapRows(patches));
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }

  bool _isNthRow(int nth, int index) {
    if (index == 0) {
      return true;
    }

    return index % nth == 0;
  }

  @override
  List<DataGridRow> get rows => _rows;
}
