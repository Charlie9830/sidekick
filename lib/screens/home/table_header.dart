import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final bool? hasSelections;
  final List<TableHeaderColumn> columns;
  final Function(bool? value) onSelectAll;

  const TableHeader({
    Key? key,
    required this.columns,
    required this.hasSelections,
    required this.onSelectAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  tristate: true,
                  value: hasSelections,
                  onChanged: onSelectAll,
                ),
                const SizedBox(width: 16),
                ...columns.map(
                  (column) => SizedBox(
                    width: column.width,
                    child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.labelLarge!,
                        child: column.label),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }
}

class TableHeaderColumn {
  final Widget label;
  final double width;

  const TableHeaderColumn({
    required this.label,
    required this.width,
  });
}
