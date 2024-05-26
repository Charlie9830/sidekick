import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/screens/home/column_widths.dart';

class TableRow extends StatelessWidget {
  final bool selected;
  final bool rangeSelected;
  final List<Widget> cells;
  final void Function(bool selected) onPressed;

  const TableRow({
    Key? key,
    this.selected = false,
    this.rangeSelected = false,
    required this.onPressed,
    required this.cells,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(cells.length == ColumnWidths.asList.length,
        'Cells.length does not equal ColumnWidths.asList.length');

    return InkWell(
      onTap: () => onPressed(!selected),
      child: Container(
        color: rangeSelected
            ? Colors.green[900]
            : selected
                ? Theme.of(context).focusColor
                : null,
        child: SizedBox(
            height: 56,
            child: Row(children: [
              const SizedBox(
                  width:
                      56), // Offset to match Header Row Left Padding (Checkbox etc),
              ...cells
                  .mapIndexed((index, element) => SizedBox(
                        width: ColumnWidths.asList[index],
                        child: cells[index],
                      ))
                  .toList(),
            ])),
      ),
    );
  }
}
