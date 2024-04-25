import 'package:flutter/material.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/power_patch/power_outlet_data_source.dart';
import 'package:sidekick/screens/power_patch/power_patch_column_names.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class PowerPatch extends StatefulWidget {
  final PowerPatchViewModel vm;
  const PowerPatch({Key? key, required this.vm}) : super(key: key);

  @override
  State<PowerPatch> createState() => _PowerPatchState();
}

class _PowerPatchState extends State<PowerPatch> {
  late final DataGridController _controller;
  late final PowerOutletDataSource _dataSource;

  double _phaseALoad = 0;
  double _phaseBLoad = 0;
  double _phaseCLoad = 0;

  @override
  void initState() {
    _controller = DataGridController();
    _dataSource = PowerOutletDataSource(outlets: widget.vm.outlets);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant PowerPatch oldWidget) {
    if (oldWidget.vm.outlets != widget.vm.outlets) {
      _dataSource.update(widget.vm.outlets);

      _phaseALoad = (widget.vm.outlets
          .where((outlet) => outlet.phase == 1)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseBLoad = (widget.vm.outlets
          .where((outlet) => outlet.phase == 2)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseCLoad = (widget.vm.outlets
          .where((outlet) => outlet.phase == 3)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 48,
        child: Card(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.cable),
              label: const Text('Patch'),
              onPressed: widget.vm.onGeneratePatch,
            ),
            IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () =>
                    widget.vm.onAddSpareOutlet(_controller.selectedIndex)),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BalanceGauge(
                    phaseALoad: _phaseALoad,
                    phaseBLoad: _phaseBLoad,
                    phaseCLoad: _phaseCLoad)
              ],
            ))
          ],
        )),
      ),
      Expanded(
        child: SfDataGrid(
          controller: _controller,
          selectionMode: SelectionMode.single,
          columns: _buildGridColumns(),
          source: _dataSource,
          columnWidthMode: ColumnWidthMode.fill,
        ),
      )
    ]);
  }

  List<GridColumn> _buildGridColumns() {
    alignLeft(Widget child) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );

    return [
      GridColumn(
        columnName: Columns.patchNumber,
        label: alignLeft(const Text('Patch #')),
        columnWidthMode: ColumnWidthMode.fitByColumnName,
      ),
      GridColumn(
        columnName: Columns.multiOutlet,
        label: alignLeft(const Text('Multi Outlet')),
        columnWidthMode: ColumnWidthMode.fitByColumnName,
      ),
      GridColumn(
        columnName: Columns.multiCircuit,
        label: alignLeft(const Text('Multi Circuit')),
        columnWidthMode: ColumnWidthMode.fitByColumnName,
      ),
      GridColumn(
        columnName: Columns.phaseNumber,
        label: const Align(alignment: Alignment.center, child: Text('Phase')),
        columnWidthMode: ColumnWidthMode.fitByColumnName,
      ),
      GridColumn(
        columnName: Columns.fixtureId,
        label: alignLeft(const Text('Fixture #')),
      ),
      GridColumn(
        columnName: Columns.fixtureType,
        label: alignLeft(const Text('Type')),
      ),
      GridColumn(
        columnName: Columns.amps,
        label: alignLeft(const Text('Amps')),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
