import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sidekick/full_screen_dialog_header.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';
import 'package:sidekick/screens/file/import_module/row_error_item.dart';
import 'package:sidekick/screens/file/import_module/row_side.dart';
import 'package:sidekick/screens/file/import_module/table_header.dart';
import 'package:sidekick/screens/file/import_module/table_header_card.dart';
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
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FullScreenDialogHeader(
              title: 'Import Manager',
              trailing: Row(
                children: [
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
                  )
                ],
              ),
              onClosed: () => Navigator.of(context).pop()),
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
                  child: _buildFixtureTable(context))),
          _buildErrorPane(context),
        ],
      ),
    );
  }

  Widget _buildErrorPane(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              elevation: 10,
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
        ));
  }

  void _handleSelectionUpdate(UpdateType type, Set<String> items) {
    if (items.isNotEmpty) {
      widget.vm.onRowSelectionChanged(items.first);
    }
  }

  Widget _buildFixtureTable(BuildContext context) {
    return Column(
      children: [
        _buildFixtureTableHeaders(context),
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.only(left: 12),
                itemExtent: CellGeometry.itemExtent,
                itemCount: widget.vm.rowPairings.length,
                itemBuilder: (context, index) {
                  return _buildFixtureTableRow(
                      context, widget.vm.rowPairings[index]);
                }))
      ],
    );
  }

  Widget _buildFixtureTableRow(BuildContext context, RowPairViewModel pairVm) {
    return ItemSelectionListener<String>(
      value: pairVm.selectionId,
      child: SizedBox(
        height: CellGeometry.itemExtent,
        child: Container(
          color: widget.vm.selectedRow == pairVm.selectionId
              ? Theme.of(context).focusColor
              : null,
          child: Row(
            children: [
              // Incoming Data.
              Expanded(
                  child: pairVm.incoming == null
                      ? const NoRowSide()
                      : RowSide(
                          hasErrors: pairVm.incoming!.errors.isNotEmpty,
                          fid: pairVm.incoming!.fid,
                          fixtureType: pairVm.incoming!.fixtureType,
                          location: pairVm.incoming!.location,
                          address: pairVm.incoming!.address,
                          universe: pairVm.incoming!.universe,
                        )),

              // Match Column
              SizedBox(width: CellGeometry.matchWidth),

              // Existing Data.
              Expanded(
                child: pairVm.existing == null
                    ? const NoRowSide()
                    : RowSide(
                        hasErrors: false,
                        fid: pairVm.existing!.fixture.fid.toString(),
                        fixtureType: pairVm.existing!.fixtureTypeName,
                        location: pairVm.existing!.locationName,
                        universe: pairVm.existing!.fixture.dmxAddress.universe,
                        address: pairVm.existing!.fixture.dmxAddress.address,
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixtureTableHeaders(BuildContext context) {
    return SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Expanded(child: TableHeader()),
            SizedBox(
                width: CellGeometry.matchWidth,
                child: TableHeaderCard(
                    child: Center(
                        child: Text('Match',
                            style: Theme.of(context).textTheme.labelLarge)))),
            const Expanded(child: TableHeader()),
          ],
        ));
  }

  @override
  void dispose() {
    _selectionFocusNode.dispose();
    super.dispose();
  }
}
