import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/home/column_widths.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

class TableRow extends StatefulWidget {
  final bool selected;
  final bool rangeSelected;
  final List<Widget> cells;
  final void Function(bool selected) onPressed;

  const TableRow({
    super.key,
    this.selected = false,
    this.rangeSelected = false,
    required this.onPressed,
    required this.cells,
  });

  @override
  State<TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.cells.length == ColumnWidths.asList.length,
        'Cells.length does not equal ColumnWidths.asList.length');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onPressed(!widget.selected),
        child: Container(
          color: _backgroundColor(),
          child: SizedBox(
              height: 56,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                      width:
                          56), // Offset to match Header Row Left Padding (Checkbox etc),
                  ...widget.cells
                      .mapIndexed((index, element) => SizedBox(
                            width: ColumnWidths.asList[index],
                            child: widget.cells[index],
                          ))
                      ,
                ],
              )),
        ),
      ),
    );
  }

  Color? _backgroundColor() {
    if (widget.rangeSelected) {
      return SidekickColors.rowRangeSelected;
    }
    if (widget.selected) {
      return SidekickColors.rowSelected;
    }
    if (_hovered) {
      return SidekickColors.rowHover;
    }
    return null;
  }
}
