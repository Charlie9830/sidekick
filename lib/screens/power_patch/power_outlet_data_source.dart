import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';
import 'package:sidekick/screens/power_patch/power_patch_column_names.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class PowerOutletDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];

  PowerOutletDataSource({required List<PowerOutletModel> outlets}) {
    _rows = _mapRows(outlets);
  }

  @override
  List<DataGridRow> get rows => _rows;

  PowerOutletDataSource.initial() : _rows = [];

  List<DataGridRow> _mapRows(List<PowerOutletModel> outlets) {
    return outlets.mapIndexed((index, outlet) {
      final multiOutlet = ((index + 1) / 6).ceil();
      final isFirstMultiOutletRow = _isNthRow(6, index);
      final patchNumber = index + 1;

      return DataGridRow(
        cells: [
          DataGridCell<int>(
              columnName: Columns.patchNumber, value: patchNumber),
          DataGridCell<String>(
            columnName: Columns.multiOutlet,
            value: isFirstMultiOutletRow ? multiOutlet.toString() : '-',
          ),
          DataGridCell<int>(
            columnName: Columns.multiCircuit,
            value: _getMultiCircuit(patchNumber),
          ),
          DataGridCell<int>(
              columnName: Columns.phaseNumber, value: outlet.phase),
          DataGridCell<String>(
              columnName: Columns.fixtureId,
              value: outlet.child.fixtures.isEmpty
                  ? ''
                  : outlet.child.fixtures
                      .map((fixture) => fixture.fid)
                      .join(', ')),
          DataGridCell<String>(
              columnName: Columns.fixtureType,
              value: outlet.child.fixtures.isEmpty
                  ? ''
                  : outlet.child.fixtures.first.type.name),
          DataGridCell<double>(
              columnName: Columns.amps, value: outlet.child.amps),
        ],
      );
    }).toList();
  }

  void update(List<PowerOutletModel> outlet) {
    _rows.clear();
    _rows.addAll(_mapRows(outlet));
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      if (e.columnName == Columns.phaseNumber) {
        return PhaseIcon(phaseNumber: e.value as int);
      }

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

  int _getMultiCircuit(int patchNumber) {
    final circuitNumber = patchNumber % 6;

    if (circuitNumber == 0) {
      return 6;
    }

    return circuitNumber;
  }
}
