import 'package:flutter/material.dart';
import 'package:sidekick/screens/home/column_widths.dart';
import 'package:sidekick/screens/home/table_header.dart';
import 'package:sidekick/widgets/icon_label.dart';

class FixtureTableHeader extends StatelessWidget {
  final bool? hasSelections;
  final void Function()? onSelectAllFixtures;
  final void Function(Set<String> ids)? onSelectedFixturesChanged;

  const FixtureTableHeader({
    super.key,
    this.hasSelections,
    this.onSelectAllFixtures,
    this.onSelectedFixturesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TableHeader(
      hasSelections: hasSelections,
      enabled: onSelectAllFixtures != null,
      onSelectAll: (value) {
        if (value == true) {
          onSelectAllFixtures?.call();
        } else {
          onSelectedFixturesChanged?.call({});
        }
      },
      columns: const [
        TableHeaderColumn(
            width: ColumnWidths.sequence,
            label: Text(
              'Seq#',
            )),
        TableHeaderColumn(width: ColumnWidths.fid, label: Text('Fix#')),
        TableHeaderColumn(width: ColumnWidths.type, label: Text('Type')),
        TableHeaderColumn(width: ColumnWidths.mode, label: Text('Mode')),
        TableHeaderColumn(
            width: ColumnWidths.location, label: Text('Location')),
        TableHeaderColumn(width: ColumnWidths.address, label: Text('Address')),
        TableHeaderColumn(
          width: ColumnWidths.powerPatch,
          label: IconLabel(
              icon: Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
              label: 'Patch'),
        ),
      ],
    );
  }
}
