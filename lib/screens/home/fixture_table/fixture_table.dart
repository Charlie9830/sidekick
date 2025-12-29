import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/home/fixture_table/fixture_table_header.dart';
import 'package:sidekick/screens/home/fixture_table/fixture_table_row.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
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
              OutlineButton(
                leading: const Icon(Icons.numbers),
                onPressed: widget.vm.selectedFixtureIds.isNotEmpty
                    ? widget.vm.onSetSequenceButtonPressed
                    : null,
                child: const Text("Set Sequence"),
              ),
            ],
          )),
          FixtureTableHeader(
            hasSelections: widget.vm.hasSelections,
            onSelectAllFixtures: widget.vm.onSelectAllFixtures,
            onSelectedFixturesChanged: widget.vm.onSelectedFixturesChanged,
          ),
          Expanded(
            child: ListView.builder(
                key: fixturesTablePageStorageKey,
                itemCount: rowVms.length,
                itemBuilder: (context, index) => FixtureTableRow(
                      vm: rowVms[index],
                      onSelectChanged: _handleSelectChanged,
                      rangeSelectFixtureStartId: _rangeSelectStartFixtureId,
                    )),
          ),
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
