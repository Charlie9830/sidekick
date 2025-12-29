import 'package:shadcn_flutter/shadcn_flutter.dart';

class TableHeader extends StatelessWidget {
  final bool? hasSelections;
  final List<TableHeaderColumn> columns;
  final Function(bool? value) onSelectAll;
  final bool enabled;

  const TableHeader({
    Key? key,
    required this.columns,
    required this.hasSelections,
    required this.onSelectAll,
    this.enabled = true,
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
                    state: switch (hasSelections) {
                      null => CheckboxState.indeterminate,
                      true => CheckboxState.checked,
                      false => CheckboxState.unchecked,
                    },
                    onChanged: enabled
                        ? (cbState) => onSelectAll(switch (cbState) {
                              CheckboxState.checked ||
                              CheckboxState.indeterminate =>
                                true,
                              CheckboxState.unchecked => false
                            })
                        : null),
                const SizedBox(width: 16),
                ...columns.map(
                  (column) => SizedBox(
                    width: column.width,
                    child: DefaultTextStyle(
                        style: Theme.of(context).typography.base,
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
