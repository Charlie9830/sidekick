import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/power_patch/power_outlet_data_source.dart';
import 'package:sidekick/screens/power_patch/power_patch_column_names.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';
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
    _dataSource = PowerOutletDataSource(widget.vm.rowViewModels);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant PowerPatch oldWidget) {
    if (oldWidget.vm.rowViewModels != widget.vm.rowViewModels) {
      _dataSource.update(widget.vm.rowViewModels);

      final outlets =
          widget.vm.rowViewModels.map((rowVm) => rowVm.outlet).toList();

      _phaseALoad = (outlets
          .where((outlet) => outlet.phase == 1)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseBLoad = (outlets
          .where((outlet) => outlet.phase == 2)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseCLoad = (outlets
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
        height: 64,
        child: Card(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () =>
                  widget.vm.onDeleteSpareOutlet(_controller.selectedIndex),
            ),
            const VerticalDivider(
              indent: 8,
              endIndent: 8,
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 110,
              child: PropertyField(
                textAlign: TextAlign.center,
                label: 'Balance Tolerance',
                suffix: '%',
                value: widget.vm.balanceTolerancePercent,
                onBlur: widget.vm.onBalanceToleranceChanged,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
                width: 124,
                child: PropertyField(
                  textAlign: TextAlign.center,
                  label: 'Max Piggyback Break',
                  value: widget.vm.maxSequenceBreak.toString(),
                  onBlur: widget.vm.onMaxSequenceBreakChanged,
                )),
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
          columnName: Columns.location,
          label: alignLeft(const Text('Location'))),
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
