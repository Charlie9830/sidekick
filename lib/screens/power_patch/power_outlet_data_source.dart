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
      final isFirstMultiOutletRow = _isNthRow(6, index);

      return PowerOutletDataGridRow(
        index: index,
        drawBottomBorder: outlet.multiPatch == 6,
        isSpare: outlet.isSpare,
        cells: [
          DataGridCell<int>(columnName: Columns.patchNumber, value: index + 1),
          DataGridCell<String>(
            columnName: Columns.multiOutlet,
            value: isFirstMultiOutletRow ? outlet.multiOutlet.toString() : '-',
          ),
          DataGridCell<int>(
            columnName: Columns.multiCircuit,
            value: outlet.multiPatch,
          ),
          DataGridCell<int>(
              columnName: Columns.phaseNumber, value: outlet.phase),
          DataGridCell<String>(
            columnName: Columns.location,
            value: outlet.child.fixtures.isNotEmpty
                ? outlet.child.fixtures.first.location
                : '',
          ),
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

  PowerOutletDataGridRow({
    required super.cells,
    required this.isSpare,
    required this.index,
    required this.drawBottomBorder,
  });
}
