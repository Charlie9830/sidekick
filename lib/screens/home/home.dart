import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/containers/data_patch_container.dart';
import 'package:sidekick/containers/export_container.dart';
import 'package:sidekick/containers/loom_names_container.dart';
import 'package:sidekick/containers/power_patch_container.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/screens/home/range_select.dart';
import 'package:sidekick/view_models/home_view_model.dart';

class Home extends StatefulWidget {
  final HomeViewModel vm;

  const Home({Key? key, required this.vm}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final FocusNode _focus;

  bool _isShiftDown = false;

  RangeSelect? _rangeSelectStart = null;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(debugLabel: "Home Table Keyboard Focus");
    // Initialize App
    widget.vm.onAppInitialize();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: DefaultTabController(
        animationDuration: Duration.zero,
        length: 5,
        initialIndex: 0,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("It's Just a Phase!"),
            primary: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(
                    icon: Icon(Icons.lightbulb),
                    child: Text('Fixtures'),
                  ),
                  Tab(
                    icon: Icon(Icons.electric_bolt),
                    child: Text('Patch'),
                  ),
                  Tab(
                      icon: Icon(Icons.settings_input_svideo),
                      child: Text('Patch')),
                  Tab(
                    icon: Icon(Icons.label),
                    child: Text('Labels'),
                  ),
                  Tab(
                    icon: Icon(Icons.save_alt),
                    child: Text('Export'),
                  )
                ]),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFixtureTable(context),
              const PowerPatchContainer(),
              const DataPatchContainer(),
              const LoomNamesContainer(),
              const ExportContainer(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => widget.vm.onAppInitialize(),
            child: const Icon(Icons.light),
          ),
        ),
      ),
    );
  }

  Widget _buildFixtureTable(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        onSelectAll: (value) {
          if (value == true) {
            widget.vm.onSelectedFixturesChanged(widget.vm.fixtures.values
                .map((fixture) => fixture.uid)
                .toSet());
          } else {
            widget.vm.onSelectedFixturesChanged({});
          }
        },
        showCheckboxColumn: true,
        columns: const [
          DataColumn(
              label: Text(
            'Sequence #',
          )),
          DataColumn(label: Text('Fixture #')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Address')),
          DataColumn(
            label: Row(children: [
              Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
              SizedBox(width: 4),
              Text('Multi'),
            ]),
          ),
          DataColumn(
            label: Row(children: [
              Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
              SizedBox(width: 4),
              Text('Patch'),
            ]),
          ),
          DataColumn(
            label: Row(children: [
              Icon(Icons.settings_input_svideo, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Text('Multi'),
            ]),
          ),
          DataColumn(
            label: Row(children: [
              Icon(Icons.settings_input_svideo, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Text('Patch'),
            ]),
          ),
        ],
        rows: widget.vm.fixtures.values.mapIndexed((index, fixture) {
          return DataRow(
              selected: widget.vm.selectedFixtureIds.contains(fixture.uid),
              onSelectChanged: (isSelected) =>
                  _handleSelectChanged(isSelected, index, fixture),
              cells: [
                DataCell(Text(fixture.sequence.toString())),
                DataCell(Text(fixture.fid.toString())),
                DataCell(
                  Text(fixture.type.name),
                ),
                DataCell(
                  Text(fixture.lookupLocation(widget.vm.locations).name),
                ),
                DataCell(
                  Text(
                      '${fixture.dmxAddress.universe}/${fixture.dmxAddress.address}'),
                ),
                DataCell(Text(fixture.powerMulti)), // Power Multi
                DataCell(Text(
                  fixture.powerPatch == 0 ? '' : fixture.powerPatch.toString(),
                )), // Power Patch
                DataCell(Text(fixture.dataMulti)), // Data Multi
                DataCell(Text(fixture.dataPatch)), // Data Patch
              ]);
        }).toList(),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent e) {
    // Shift
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
          _rangeSelectStart = null;
        });
      }
    }
  }

  void _handleSelectChanged(bool? isSelected, int index, FixtureModel fixture) {
    if (isSelected == null) {
      debugPrint("isSelected is Null");
      return;
    }

    if (_isShiftDown == false) {
      // Normal Selection
      if (isSelected == true) {
        widget.vm.onSelectedFixturesChanged(
            {...widget.vm.selectedFixtureIds, fixture.uid});
      } else {
        widget.vm.onSelectedFixturesChanged(
            widget.vm.selectedFixtureIds..remove(fixture.uid));
      }
    } else {
      // Range Selection.
      if (_rangeSelectStart == null) {
        _rangeSelectStart = RangeSelect(index, isSelected);
        widget.vm.onSelectedFixturesChanged(
            {...widget.vm.selectedFixtureIds, fixture.uid});
      } else {
        if (_rangeSelectStart!.value == true) {
          widget.vm.onSelectedFixturesChanged({
            ...widget.vm.selectedFixtureIds,
            ..._getRangeSelectionIds(_rangeSelectStart!.startingIndex, index,
                widget.vm.fixtures.values.toList())
          });
        } else {
          widget.vm.onSelectedFixturesChanged({
            ...widget.vm.selectedFixtureIds
              ..removeAll(_getRangeSelectionIds(
                  _rangeSelectStart!.startingIndex,
                  index,
                  widget.vm.fixtures.values.toList()))
          });
        }
      }
    }
  }

  List<String> _getRangeSelectionIds(
      int startingIndex, int endingIndex, List<FixtureModel> fixtures) {
    final (coercedStartingIndex, coercedEndingIndex) =
        _sortIndexes(startingIndex, endingIndex);

    final safeEndingIndex = coercedEndingIndex < fixtures.length - 1
        ? coercedEndingIndex + 1
        : coercedEndingIndex;

    return fixtures
        .toList()
        .sublist(coercedStartingIndex, safeEndingIndex)
        .map((fixture) => fixture.uid)
        .toList();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }
}

(int startingIndex, int endingIndex) _sortIndexes(
    int startingIndex, int endingIndex) {
  if (startingIndex > endingIndex) {
    return (endingIndex, startingIndex);
  }

  return (startingIndex, endingIndex);
}
