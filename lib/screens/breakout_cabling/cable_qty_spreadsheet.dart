import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class CableQtySpreadsheet extends StatelessWidget {
  final List<LocationViewModel> locationVms;
  final String selectedLocationId;
  const CableQtySpreadsheet({
    super.key,
    required this.locationVms,
    required this.selectedLocationId,
  });

  @override
  Widget build(BuildContext context) {
    final List<CableQtyGroup> allGroups = CableQtyGroup.allGroups;
    final borderColor = Theme.of(context).colorScheme.border;
    final borderSide = BorderSide(color: borderColor, width: 0.25);

    return Card(
      child: TableView.builder(
        columnCount: locationVms.length + 1,
        rowCount: allGroups.length + 1,
        columnBuilder: (index) {
          if (index == 0) {
            return const TableSpan(extent: FixedSpanExtent(124));
          }

          final location = locationVms.elementAtOrNull(index - 1);

          return TableSpan(
            backgroundDecoration: location?.location.uid == selectedLocationId
                ? SpanDecoration(color: Colors.gray.shade900)
                : null,
            foregroundDecoration: SpanDecoration(
              border: SpanBorder(leading: borderSide),
            ),
            extent: const FixedSpanExtent(32),
          );
        },
        rowBuilder: (index) {
          if (index == 0) {
            return const TableSpan(extent: FixedSpanExtent(200));
          }

          final currentType = allGroups[index - 1].type;
          final nextType = allGroups.elementAtOrNull(index)?.type;

          return TableSpan(
            extent: const FixedSpanExtent(32),
            foregroundDecoration: SpanDecoration(
              border: SpanBorder(
                leading: borderSide,
                trailing: currentType != nextType
                    ? borderSide.copyWith(width: 2)
                    : BorderSide.none,
              ),
            ),
          );
        },
        cellBuilder: (context, vic) => _cellBuilder(context, vic, allGroups),
      ),
    );
  }

  TableViewCell _cellBuilder(
    BuildContext context,
    TableVicinity vicinity,
    List<CableQtyGroup> allGroups,
  ) {
    if (vicinity.row == 0) {
      // Header Row
      return _buildHeaderCell(context, vicinity.column);
    }

    if (vicinity.column == 0) {
      return _buildCableTypeCell(context, vicinity.row, allGroups);
    }

    return _buildContentCell(context, vicinity, allGroups);
  }

  TableViewCell _buildHeaderCell(BuildContext context, int columnIndex) {
    if (columnIndex == 0) {
      return const TableViewCell(child: SizedBox());
    }
    final location = locationVms.elementAtOrNull(columnIndex - 1);
    return TableViewCell(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              location?.location.name ?? '',
              style: Theme.of(context).typography.small,
            ),
          ),
        ),
      ),
    );
  }

  TableViewCell _buildCableTypeCell(
    BuildContext context,
    int rowIndex,
    List<CableQtyGroup> allGroups,
  ) {
    final cableGroup = allGroups.elementAtOrNull(rowIndex - 1);
    return TableViewCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          cableGroup?.label ?? '',
          style: Theme.of(context).typography.small,
        ),
      ),
    );
  }

  TableViewCell _buildContentCell(
    BuildContext context,
    TableVicinity vicinity,
    List<CableQtyGroup> allGroups,
  ) {
    final location = locationVms.elementAtOrNull(vicinity.column - 1);
    final qtyGroup = allGroups.elementAtOrNull(vicinity.row - 1);

    if (location == null || qtyGroup == null) {
      return const TableViewCell(child: Text(''));
    }

    final cellValue = location.cableQtys[qtyGroup]?.toString() ?? '';

    return TableViewCell(child: Center(child: Text(cellValue)));
  }
}
