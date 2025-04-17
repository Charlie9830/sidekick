import 'package:collection/collection.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';
import 'package:sidekick/screens/file/import_module/row_error_item.dart';
import 'package:sidekick/screens/file/import_module/row_side.dart';
import 'package:sidekick/screens/file/import_module/table_header.dart';
import 'package:sidekick/view_models/import_manager_view_model.dart';
import 'package:path/path.dart' as p;

class ImportManager extends StatefulWidget {
  final ImportManagerViewModel vm;
  const ImportManager({
    super.key,
    required this.vm,
  });

  @override
  State<ImportManager> createState() => _ImportManagerState();
}

class _ImportManagerState extends State<ImportManager> {
  late final FocusNode _selectionFocusNode;

  @override
  void initState() {
    _selectionFocusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('Import Manager'),
        actions: [
          Tooltip(
            message: widget.vm.importFilePath,
            child: Text(
              p.basename(widget.vm.importFilePath),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.vm.onRefreshButtonPressed,
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
              width: 180,
              child: Card(
                elevation: 2,
                child: EasyStepper(
                  lineStyle: const LineStyle(
                    lineType: LineType.normal,
                  ),
                  direction: Axis.vertical,
                  activeStep: widget.vm.step,
                  enableStepTapping: false,
                  showLoadingAnimation: false,
                  defaultStepBorderType: BorderType.normal,
                  stepRadius: 32,
                  steps: const [
                    EasyStep(icon: Icon(Icons.dry_cleaning), title: 'Validate'),
                    EasyStep(
                      icon: Icon(Icons.merge),
                      title: 'Merge',
                    )
                  ],
                ),
              )),
          Expanded(
              child: Column(
            children: [
              Expanded(
                flex: 2,
                child: ItemSelectionContainer<String>(
                    focusNode: _selectionFocusNode,
                    itemIndicies: Map<String, int>.fromEntries(
                        widget.vm.rowPairings.mapIndexed((index, pairVm) =>
                            MapEntry(pairVm.selectionId, index))),
                    selectedItems: {
                      widget.vm.selectedRow,
                    },
                    onSelectionUpdated: _handleSelectionUpdate,
                    child: _buildIncomingFixtureTable(context)),
              ),
              if (widget.vm.rowErrors.isNotEmpty)
                Expanded(flex: 1, child: _buildErrorPane(context)),
            ],
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: widget.vm.onNextButtonPressed,
          label: const Text('Next'),
          icon: const Icon(Icons.arrow_circle_right)),
    );
  }

  Widget _buildErrorPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero)),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Errors and Warnings'),
            ),
          ),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: widget.vm.rowErrors.length,
          itemBuilder: (context, index) =>
              RowErrorItem(value: widget.vm.rowErrors[index]),
        )),
      ],
    );
  }

  void _handleSelectionUpdate(UpdateType type, Set<String> items) {
    if (items.isNotEmpty) {
      widget.vm.onRowSelectionChanged(items.first);
    }
  }

  Widget _buildIncomingFixtureTable(BuildContext context) {
    return Column(
      children: [
        _buildIncomingFixtureTableHeaders(context),
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.only(left: 12),
                itemExtent: CellGeometry.itemExtent,
                itemCount: widget.vm.incomingRowVms.length,
                itemBuilder: (context, index) {
                  return _buildIncomignFixtureTableRow(
                      context, widget.vm.incomingRowVms[index]);
                }))
      ],
    );
  }

  Widget _buildIncomignFixtureTableRow(
      BuildContext context, RawRowViewModel rowVm) {
    return ItemSelectionListener<String>(
      value: rowVm.selectionId,
      child: SizedBox(
        height: CellGeometry.itemExtent,
        child: Container(
          color: widget.vm.selectedRow == rowVm.selectionId
              ? Theme.of(context).focusColor
              : null,
          child: Row(
            children: [
              // Incoming Data.
              Expanded(
                  child: RowSide(
                hasErrors: rowVm.row.errors.isNotEmpty,
                fid: rowVm.row.fid,
                fixtureType: rowVm.row.fixtureType,
                location: rowVm.row.location,
                address: rowVm.row.address,
                universe: rowVm.row.universe,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingFixtureTableHeaders(BuildContext context) {
    return const SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(child: TableHeader()),
          ],
        ));
  }

  @override
  void dispose() {
    _selectionFocusNode.dispose();
    super.dispose();
  }
}
