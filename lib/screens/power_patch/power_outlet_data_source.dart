import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';
import 'package:sidekick/screens/power_patch/power_patch_column_names.dart';
import 'package:sidekick/view_models/power_patch_row_view_model.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class PowerOutletDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];

  PowerOutletDataSource(
    List<PowerPatchRowViewModel> rowVms,
  ) {
    _rows = _mapRows(rowVms);
  }

  @override
  List<DataGridRow> get rows => _rows;

  PowerOutletDataSource.initial() : _rows = [];

  List<DataGridRow> _mapRows(List<PowerPatchRowViewModel> rowVms) {
    return rowVms.mapIndexed((index, vm) {
      final isFirstMultiOutletRow = _isNthRow(6, index);

      return PowerOutletDataGridRow(
        index: index,
        drawBottomBorder: vm.outlet.multiPatch == 6,
        isSpare: vm.outlet.isSpare,
        locationName: vm.location.name,
        cells: [
          DataGridCell<int>(columnName: Columns.patchNumber, value: index + 1),
          DataGridCell<String>(
            columnName: Columns.multiOutlet,
            value: isFirstMultiOutletRow ? vm.multiOutlet.name : '-',
          ),
          DataGridCell<int>(
            columnName: Columns.multiCircuit,
            value: vm.outlet.multiPatch,
          ),
          DataGridCell<int>(
              columnName: Columns.phaseNumber, value: vm.outlet.phase),
          DataGridCell<String>(
            columnName: Columns.location,
            value: vm.location.name,
          ),
          DataGridCell<String>(
              columnName: Columns.fixtureId,
              value: vm.outlet.child.fixtures.isEmpty
                  ? ''
                  : vm.outlet.child.fixtures
                      .map((fixture) => fixture.fid)
                      .join(', ')),
          DataGridCell<String>(
              columnName: Columns.fixtureType,
              value: vm.outlet.child.fixtures.isEmpty
                  ? ''
                  : vm.outlet.child.fixtures.first.type.name),
          DataGridCell<double>(
              columnName: Columns.amps, value: vm.outlet.child.amps),
        ],
      );
    }).toList();
  }

  void update(List<PowerPatchRowViewModel> rowVms) {
    // TODO Maybe a performance issue here. Clearing and recreating the entire collection.
    _rows.clear();
    _rows.addAll(_mapRows(rowVms));
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    if (row is! PowerOutletDataGridRow) {
      throw "Row is not of type PowerOutletDataGridRow";
    }

    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      Widget bottomBorder(Widget child) => row.drawBottomBorder
          ? Container(
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: child,
            )
          : child;

      if (e.columnName == Columns.patchNumber) {
        return bottomBorder(Row(children: [
          if (row.isSpare)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, right: 8.0),
              child: Icon(Icons.sports_martial_arts_outlined),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(e.value.toString()),
          )
        ]));
      }

      if (e.columnName == Columns.phaseNumber) {
        return bottomBorder(PhaseIcon(phaseNumber: e.value as int));
      }

      return bottomBorder(Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      ));
    }).toList());
  }

  bool _isNthRow(int nth, int index) {
    if (index == 0) {
      return true;
    }

    return index % nth == 0;
  }
}

class PowerOutletDataGridRow extends DataGridRow {
  final int index;
  final bool drawBottomBorder;
  final bool isSpare;
  final String locationName;

  PowerOutletDataGridRow({
    required super.cells,
    required this.isSpare,
    required this.index,
    required this.locationName,
    required this.drawBottomBorder,
  });
}
