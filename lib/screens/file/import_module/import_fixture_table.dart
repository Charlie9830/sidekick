import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';
import 'package:sidekick/screens/file/import_module/table_header.dart';
import 'package:sidekick/view_models/import_manager_view_model.dart';


class ImportFixtureTable extends StatelessWidget {
  final Set<String> selectedRows;
  final List<RowPairViewModel> rowPairs;
  final FocusNode selectionFocusNode;
  final void Function(String id) onRowSelectionChanged;

  const ImportFixtureTable({
    super.key,
    required this.selectionFocusNode,
    required this.rowPairs,
    required this.selectedRows,
    required this.onRowSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
        focusNode: selectionFocusNode,
        itemIndicies: Map<String, int>.fromEntries(rowPairs.mapIndexed(
            (index, pairVm) => MapEntry(pairVm.selectionId, index))),
        selectedItems: selectedRows,
        onSelectionUpdated: _handleSelectionUpdate,
        child: _buildIncomingFixtureTable(context));
  }

  void _handleSelectionUpdate(UpdateType type, Set<String> items) {
    if (items.isNotEmpty) {
      onRowSelectionChanged(items.first);
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
                itemCount: rowPairs.length,
                itemBuilder: (context, index) {
                  return _buildFixtureTableRow(context, rowPairs[index]);
                }))
      ],
    );
  }

  Widget _buildFixtureTableRow(BuildContext context, RowPairViewModel rowPair) {
    return Text("Hello");
    // return ItemSelectionListener<String>(
    //   value: rowPair.selectionId,
    //   child: SizedBox(
    //     height: CellGeometry.itemExtent,
    //     child: Container(
    //       color: widget.vm.selectedRow == rowPair.selectionId
    //           ? Theme.of(context).focusColor
    //           : null,
    //       child: Row(
    //         children: [
    //           // Incoming Data.
    //           Expanded(
    //               child: RowSide(
    //             hasErrors: rowPair.errors.isNotEmpty,
    //             fid: rowPair.row.fid,
    //             fixtureType: rowPair.row.fixtureType,
    //             location: rowPair.row.location,
    //             address: rowPair.row.address,
    //             universe: rowPair.row.universe,
    //           )),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
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
}
