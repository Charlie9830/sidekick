import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter/services.dart';
import 'package:sidekick/containers/data_patch_container.dart';
import 'package:sidekick/containers/export_container.dart';
import 'package:sidekick/containers/fixture_types_container.dart';
import 'package:sidekick/containers/locations_container.dart';
import 'package:sidekick/containers/power_patch_container.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/home/column_widths.dart';
import 'package:sidekick/screens/home/range_select.dart';
import 'package:sidekick/screens/home/table_header.dart';
import 'package:sidekick/screens/home/table_row.dart';
import 'package:sidekick/view_models/home_view_model.dart';
import 'package:sidekick/widgets/icon_label.dart';
import 'package:sidekick/widgets/toolbar.dart';

final _modKeys = {
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

class Home extends StatefulWidget {
  final HomeViewModel vm;

  const Home({Key? key, required this.vm}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final FocusNode _focus;

  bool _isModDown = false;

  RangeSelect? _rangeSelectStart;

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
        length: 6,
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
                    icon: Icon(Icons.location_pin),
                    child: Text('Locations'),
                  ),
                  Tab(
                    icon: Icon(Icons.light),
                    child: Text('Fixture Types'),
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
              const LocationsContainer(),
              const FixtureTypesContainer(),
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
    final fixtures = widget.vm.fixtures.values.toList();

    return Column(
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
          hasSelections: widget.vm.selectedFixtureIds.length ==
                  widget.vm.fixtures.values.length
              ? true
              : (widget.vm.selectedFixtureIds.isEmpty ? false : null),
          onSelectAll: (value) {
            if (value == true) {
              widget.vm.onSelectedFixturesChanged(widget.vm.fixtures.values
                  .map((fixture) => fixture.uid)
                  .toSet());
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
                icon: Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
                label: 'Multi',
              ),
            ),
            TableHeaderColumn(
              width: ColumnWidths.powerPatch,
              label: IconLabel(
                  icon:
                      Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
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
          child: ListView.separated(
              itemCount: fixtures.length,
              separatorBuilder: (context, index) => _buildDivider(
                  fixtures[index],
                  fixtures.elementAtOrNull(index + 1),
                  widget.vm.locations),
              itemBuilder: (context, index) {
                final fixture = fixtures[index];
                return TableRow(
                  rangeSelected: _rangeSelectStart != null &&
                      _rangeSelectStart!.startingIndex == index,
                  selected: widget.vm.selectedFixtureIds.contains(fixture.uid),
                  onPressed: (isSelected) =>
                      _handleSelectChanged(isSelected, index, fixture),
                  cells: [
                    Text(fixture.sequence.toString()),
                    Text(fixture.fid.toString()),

                    Text(fixture.type.name),

                    Text(fixture.lookupLocation(widget.vm.locations).name),

                    Text(
                        '${fixture.dmxAddress.universe}/${fixture.dmxAddress.address}'),

                    Text(fixture.powerMulti), // Power Multi
                    Text(
                      fixture.powerPatch == 0
                          ? ''
                          : fixture.powerPatch.toString(),
                    ), // Power Patch
                    Text(fixture.dataMulti), // Data Multi
                    Text(fixture.dataPatch),
                  ],
                );
              }),
        ),
      ],
    );
  }

  Widget _buildDivider(FixtureModel fixture, FixtureModel? nextFixture,
      Map<String, LocationModel> locations) {
    if (nextFixture == null) {
      return const Divider(height: 0);
    }

    if (fixture.locationId != nextFixture.locationId) {
      return InkWell(
        onTap: () => widget.vm.onSelectedFixturesChanged(widget
            .vm.fixtures.values
            .where((fixture) => fixture.locationId == nextFixture.locationId)
            .map((fixture) => fixture.uid)
            .toSet()),
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
                Text(locations[nextFixture.locationId]?.name ?? '',
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

    return const Divider(height: 0);
  }

  void _handleKeyEvent(KeyEvent e) {
    if (_modKeys.contains(e.logicalKey)) {
      if (e is KeyDownEvent) {
        setState(() {
          _isModDown = true;
        });
      }

      if (e is KeyUpEvent) {
        setState(() {
          _isModDown = false;
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

    if (_isModDown == false) {
      // Normal Selection
      widget.vm.onSelectedFixturesChanged({fixture.uid});
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
