import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter/services.dart';
import 'package:sidekick/screens/home/column_widths.dart';
import 'package:sidekick/screens/home/table_header.dart';
import 'package:sidekick/screens/home/table_row.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/widgets/icon_label.dart';
import 'package:sidekick/widgets/toolbar.dart';

final _modKeys = {
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

class FixtureTable extends StatefulWidget {
  final FixtureTableViewModel vm;

  const FixtureTable({Key? key, required this.vm}) : super(key: key);

  @override
  State<FixtureTable> createState() => _FixtureTableState();
}

class _FixtureTableState extends State<FixtureTable> {
  late final FocusNode _focus;
  bool _isModDown = false;
  bool _isShiftDown = false;
  String _rangeSelectStartFixtureId = '';

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(debugLabel: "Home Table Keyboard Focus");
  }

  @override
  Widget build(BuildContext context) {
    final rowVms = widget.vm.rowVms;

    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Toolbar(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.numbers),
                label: const Text("Set Sequence"),
                onPressed: widget.vm.selectedFixtureIds.isNotEmpty
                    ? widget.vm.onSetSequenceButtonPressed
                    : null,
              ),
            ],
          )),
          TableHeader(
            hasSelections: widget.vm.hasSelections,
            onSelectAll: (value) {
              if (value == true) {
                widget.vm.onSelectAllFixtures();
              } else {
                widget.vm.onSelectedFixturesChanged({});
              }
            },
            columns: const [
              TableHeaderColumn(
                  width: ColumnWidths.sequence,
                  label: Text(
                    'Sequence #',
                  )),
              TableHeaderColumn(
                  width: ColumnWidths.fid, label: Text('Fixture #')),
              TableHeaderColumn(width: ColumnWidths.type, label: Text('Type')),
              TableHeaderColumn(
                  width: ColumnWidths.location, label: Text('Location')),
              TableHeaderColumn(
                  width: ColumnWidths.address, label: Text('Address')),
              TableHeaderColumn(
                width: ColumnWidths.powerMulti,
                label: IconLabel(
                  icon:
                      Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
                  label: 'Multi',
                ),
              ),
              TableHeaderColumn(
                width: ColumnWidths.powerPatch,
                label: IconLabel(
                    icon: Icon(Icons.electric_bolt,
                        color: Colors.yellow, size: 16),
                    label: 'Patch'),
              ),
              TableHeaderColumn(
                  width: ColumnWidths.dataMulti,
                  label: IconLabel(
                      icon: Icon(Icons.settings_input_svideo,
                          color: Colors.blue, size: 16),
                      label: 'Multi')),
              TableHeaderColumn(
                width: ColumnWidths.dataPatch,
                label: IconLabel(
                    icon: Icon(Icons.settings_input_svideo,
                        color: Colors.blue, size: 16),
                    label: 'Patch'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
                itemCount: rowVms.length,
                itemBuilder: (context, index) {
                  return switch (rowVms[index]) {
                    FixtureRowDividerVM row => _buildDivider(row),
                    FixtureViewModel row => _buildTableRow(index, row),
                    _ => const SizedBox(),
                  };
                }),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(int index, FixtureViewModel row) {
    return TableRow(
      rangeSelected: _rangeSelectStartFixtureId == row.uid,
      selected: row.selected,
      onPressed: (isSelected) =>
          _handleSelectChanged(isSelected, row.uid),
      cells: [
        _SequenceNumberCell(
          value: row.sequence.toString(),
          hasInvalidSequenceNumber: row.hasInvalidSequenceNumber,
          hasSequenceNumberBreak: row.hasSequenceNumberBreak,
        ),
        Text(row.fid.toString()),
        Text(row.type),
        Text(row.location),
        Text(row.address),
        Text(row.powerMulti), // Power Multi
        Text(
          row.powerPatch == 0 ? '' : row.powerPatch.toString(),
        ), // Power Patch
        Text(row.dataMulti), // Data Multi
        Text(row.dataPatch),
      ],
    );
  }

  Widget _buildDivider(FixtureRowDividerVM dividerVM) {
    return InkWell(
      onTap: () => dividerVM.onSelectFixtures(),
      child: Column(
        children: [
          const Divider(height: 0),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Icon(Icons.location_on,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(dividerVM.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Theme.of(context).colorScheme.primary))
            ]),
          ),
          const SizedBox(height: 24),
          const Divider(height: 0),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent e) {
    if (e.logicalKey == LogicalKeyboardKey.shiftLeft ||
        e.logicalKey == LogicalKeyboardKey.shiftRight) {
      if (e is KeyDownEvent) {
        setState(() {
          _isShiftDown = true;
        });
      }

      if (e is KeyUpEvent) {
        setState(() {
          _isShiftDown = false;
        });
      }
    }

    if (_modKeys.contains(e.logicalKey)) {
      if (e is KeyDownEvent) {
        setState(() {
          _isModDown = true;
        });
      }

      if (e is KeyUpEvent) {
        setState(() {
          _isModDown = false;
          _rangeSelectStartFixtureId = '';
        });
      }
    }
  }

  void _handleSelectChanged(bool? isSelected, String uid) {
    if (_isShiftDown == true && _isModDown == true) {
      _handleRangeSelection(uid, true);
      return;
    }

    if (_isShiftDown == true) {
      // Shift down "Additive" Selection.
      if (widget.vm.selectedFixtureIds.contains(uid)) {
        // Already selected, so De select only this row.
        widget.vm.onSelectedFixturesChanged(
            widget.vm.selectedFixtureIds.toSet()..remove(uid));
        return;
      }

      // Add the current row to the selection collection.
      widget.vm
          .onSelectedFixturesChanged({...widget.vm.selectedFixtureIds, uid});
      return;
    }

    if (_isModDown == true) {
      _handleRangeSelection(uid, _isShiftDown);
      return;
    }

    // Your normal everyday exclusive Selection.
    widget.vm.onSelectedFixturesChanged({uid});
  }

  void _handleRangeSelection(String uid, bool isAdditive) {
    // Range Selection.
    if (_rangeSelectStartFixtureId.isEmpty) {
      // Start a new Range Selection.
      _rangeSelectStartFixtureId = uid;
      widget.vm
          .onSelectedFixturesChanged({...widget.vm.selectedFixtureIds, uid});
      return;
    }

    // Complete Range Selection.
    widget.vm
        .onRangeSelectFixtures(_rangeSelectStartFixtureId, uid, isAdditive);
    _rangeSelectStartFixtureId = '';
    return;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }
}

class _SequenceNumberCell extends StatelessWidget {
  final String value;
  final bool hasSequenceNumberBreak;
  final bool hasInvalidSequenceNumber;

  const _SequenceNumberCell({
    required this.hasInvalidSequenceNumber,
    required this.hasSequenceNumberBreak,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text(value,
        style: hasSequenceNumberBreak || hasInvalidSequenceNumber
            ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: hasInvalidSequenceNumber ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold)
            : null);
  }
}
