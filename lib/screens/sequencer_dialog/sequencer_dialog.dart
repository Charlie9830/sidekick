import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/sequencer_dialog/arrowed_divider.dart';
import 'package:sidekick/screens/sequencer_dialog/fixture_spatial_sort.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_plan_view.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/widgets/property_field.dart';

const double _kMappingListItemExtent = 56;

/// How the unassigned fixtures are presented: a flat list or the spatial plot.
enum _FixtureViewMode { list, plan }

class SequencerDialog extends StatefulWidget {
  final List<FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final int nextAvailableSequenceNumber;

  const SequencerDialog({
    Key? key,
    required this.fixtures,
    required this.fixtureTypes,
    required this.nextAvailableSequenceNumber,
  }) : super(key: key);

  @override
  State<SequencerDialog> createState() => _SequencerDialogState();
}

class _SequencerDialogState extends State<SequencerDialog> {
  int _currentSequenceNumber = 1;
  Map<int, FixtureModel> _mapping = {};
  late List<FixtureModel> _fixtures;
  _FixtureViewMode _viewMode = _FixtureViewMode.list;
  FixtureSortAxis _sortAxis = FixtureSortAxis.selectionOrder;
  bool _sortDescending = false;
  late final TextEditingController _fixtureNumberController;
  late final TextEditingController _seqNumberController;
  late final ScrollController _listScrollController;
  String _error = '';
  late final FocusNode _sequenceNumberFocusNode;
  late final FocusNode _fixtureNumberFocusNode;

  @override
  void initState() {
    super.initState();
    // Focus Nodes
    _sequenceNumberFocusNode = FocusNode(
      onKeyEvent: ((node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab) {
          _fixtureNumberFocusNode.requestFocus();
          return KeyEventResult.skipRemainingHandlers;
        }
        return KeyEventResult.ignored;
      }),
    );

    _fixtureNumberFocusNode = FocusNode(
      onKeyEvent: ((node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab) {
          _sequenceNumberFocusNode.requestFocus();
          return KeyEventResult.skipRemainingHandlers;
        }
        return KeyEventResult.ignored;
      }),
    );

    // Controllers
    _fixtureNumberController = TextEditingController();
    _seqNumberController = TextEditingController(text: 1.toString());
    _listScrollController = ScrollController();

    // Fixture Collection.
    _fixtures = widget.fixtures.toList();
  }

  @override
  Widget build(BuildContext context) {
    final sortedSequenceKeys = _mapping.keys.sorted((a, b) => a - b);
    final sortedAssignedFixtures = sortedSequenceKeys
        .map((seq) => (seq, _mapping[seq]!))
        .toList();

    final assignedIds = sortedAssignedFixtures
        .map((tuple) => tuple.$2.uid)
        .toSet();

    final unassignedFixtures = _fixtures
        .where((fixture) => assignedIds.contains(fixture.uid) == false)
        .toList();

    final hasCoords = hasUsableCoords(_fixtures);

    return SizedBox(
      width: 1366,
      height: 800,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.ghost(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fixtures',
                                style: Theme.of(context).typography.lead,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_viewMode == _FixtureViewMode.list)
                                    _SortControl(
                                      axis: _sortAxis,
                                      descending: _sortDescending,
                                      hasCoords: hasCoords,
                                      onAxisChanged: (axis) =>
                                          _applySort(axis: axis),
                                      onToggleDirection: () => _applySort(
                                        descending: !_sortDescending,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  _ViewModeToggle(
                                    mode: _viewMode,
                                    planEnabled: hasCoords,
                                    onChanged: (mode) =>
                                        setState(() => _viewMode = mode),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Expanded(
                            child: _viewMode == _FixtureViewMode.list
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: unassignedFixtures.length,
                                    itemBuilder: (context, index) {
                                      final fixture = unassignedFixtures[index];

                                      return ShadListItem(
                                        key: Key(fixture.uid),
                                        title: Text(
                                          '#${fixture.fid.toString()}',
                                        ),
                                        trailing: Text(
                                          widget
                                                  .fixtureTypes[fixture.typeId]
                                                  ?.name ??
                                              '',
                                        ),
                                      );
                                    },
                                  )
                                : SequencerPlanView(
                                    fixtures: _fixtures,
                                    fixtureTypes: widget.fixtureTypes,
                                    mapping: _mapping,
                                    onAssign: _assignFixtureToCurrentSequence,
                                    onUnassign: _unassignFixture,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const ArrowedDivider(),
                    SizedBox(
                      width: 400,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlineButton(
                              leading: const Icon(
                                Icons.keyboard_double_arrow_right,
                              ),
                              onPressed: unassignedFixtures.isNotEmpty
                                  ? () => _assignRemaining(unassignedFixtures)
                                  : null,
                              child: const Text('Assign all'),
                            ),
                            const SizedBox(height: 16),
                            OutlineButton(
                              leading: const Icon(
                                Icons.keyboard_double_arrow_left,
                              ),
                              onPressed: _mapping.values.isNotEmpty
                                  ? () => setState(() => _mapping.clear())
                                  : null,
                              child: const Text('Remove All'),
                            ),
                            Row(
                              children: [
                                SimpleTooltip(
                                  message: "Round Robin Assign",
                                  child: IconButton.ghost(
                                    icon: const Icon(
                                      Icons.roundabout_right_rounded,
                                    ),
                                    onPressed: unassignedFixtures.isNotEmpty
                                        ? () => _roundRobinAssign(
                                            unassignedFixtures,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 64),
                            Row(
                              children: [
                                const Text('Sequence Number'),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 164,
                                  child: PropertyField(
                                    focusNode: _sequenceNumberFocusNode,
                                    controller: _seqNumberController,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    label: 'Sequence Number',
                                    labelAlign: LabelAlign.center,
                                    onBlur: (_) => _updateSequenceNumber(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SimpleTooltip(
                                  message: 'Next Available',
                                  child: IconButton.ghost(
                                    icon: const Icon(Icons.fast_forward),
                                    onPressed: () =>
                                        _handleFindNextAvailableSequenceNumberPressed(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text('Fixture Number'),
                                const SizedBox(width: 36),
                                SizedBox(
                                  width: 212,
                                  child: PropertyField(
                                    focusNode: _fixtureNumberFocusNode,
                                    autofocus: true,
                                    error: _error.isEmpty ? null : _error,
                                    controller: _fixtureNumberController,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onBlur: (_) => _enumerate(),
                                    submitAction:
                                        PropertyFieldSubmitAction.none,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const ArrowedDivider(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Fixtures',
                            style: Theme.of(context).typography.lead,
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemExtent: _kMappingListItemExtent,
                              controller: _listScrollController,
                              itemCount: sortedAssignedFixtures.length,
                              itemBuilder: (context, index) {
                                final (seq, fixture) =
                                    sortedAssignedFixtures[index];
                                return ShadListItem(
                                  leading: Text(seq.toString()),
                                  title: Text('#${fixture.fid.toString()}'),
                                  trailing: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget
                                                .fixtureTypes[fixture.typeId]
                                                ?.name ??
                                            '',
                                      ),
                                      IconButton.ghost(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.gray,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _mapping =
                                                Map<int, FixtureModel>.from(
                                                  _mapping,
                                                )..remove(seq);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PrimaryButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(_mapping),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applySort({FixtureSortAxis? axis, bool? descending}) {
    setState(() {
      _sortAxis = axis ?? _sortAxis;
      _sortDescending = descending ?? _sortDescending;
      // Always sort from the original selection so 'As selected' is meaningful
      // and axis sorts stay deterministic regardless of the current order.
      _fixtures = sortFixturesSpatially(
        widget.fixtures.toList(),
        _sortAxis,
        descending: _sortDescending,
      );
    });
  }

  void _handleFindNextAvailableSequenceNumberPressed() {
    setState(() {
      _currentSequenceNumber = widget.nextAvailableSequenceNumber;
      _seqNumberController.text = widget.nextAvailableSequenceNumber.toString();
    });
  }

  void _roundRobinAssign(List<FixtureModel> unassignedFixtures) {
    final fixturesByType = unassignedFixtures.groupListsBy(
      (element) => element.typeId,
    );
    final fixtureQueues = fixturesByType.entries
        .map((entry) => Queue<FixtureModel>.from(entry.value))
        .toList();

    final Map<int, FixtureModel> mapping = {};
    int mappingIndex = 0;
    int queueIndex = 0;

    while (fixtureQueues.any((queue) => queue.isNotEmpty)) {
      final currentQueue = fixtureQueues[queueIndex];

      if (currentQueue.isNotEmpty) {
        mapping[_currentSequenceNumber + mappingIndex] = currentQueue
            .removeFirst();

        mappingIndex++;
      }

      // Wrap around Queue Index.
      queueIndex = queueIndex == fixtureQueues.length - 1 ? 0 : queueIndex + 1;
    }

    setState(() {
      _mapping.addAll(mapping);
    });
  }

  void _assignRemaining(List<FixtureModel> unassignedFixtures) {
    final newEntries = unassignedFixtures.mapIndexed(
      (index, fixture) => MapEntry(_currentSequenceNumber + index, fixture),
    );

    setState(() {
      _mapping.addAll(Map<int, FixtureModel>.fromEntries(newEntries));
    });
  }

  void _updateSequenceNumber() {
    if (_seqNumberController.text.trim().isEmpty) {
      return;
    }

    _fixtureNumberFocusNode.requestFocus();
    setState(() {
      _currentSequenceNumber = int.tryParse(_seqNumberController.text) ?? 1;
    });
  }

  void _enumerate() {
    if (_fixtureNumberController.text.trim().isEmpty) {
      return;
    }

    final fid = int.parse(_fixtureNumberController.text);
    final fixture = _fixtures.firstWhereOrNull((fix) => fix.fid == fid);

    if (fixture == null) {
      // Unknown Fixture Id.
      setState(() {
        _error = "#${_fixtureNumberController.text}: Unknown Fixture";
      });

      SystemSound.play(SystemSoundType.alert);
      _fixtureNumberController.text = '';

      return;
    }

    _assignFixtureToCurrentSequence(fixture);
  }

  /// Assigns [fixture] to the current sequence number and advances to the next,
  /// guarding against a fixture being assigned twice. Shared by the fixture
  /// number field and the plan view's tap-to-assign.
  void _assignFixtureToCurrentSequence(FixtureModel fixture) {
    final duplicateFixtureEntry = _mapping.entries.firstWhereOrNull(
      (entry) => entry.value.uid == fixture.uid,
    );
    if (duplicateFixtureEntry != null) {
      setState(() {
        _error =
            'Duplicate Fixture Id:\n#${fixture.fid} at Seq ${duplicateFixtureEntry.key}';
      });

      SystemSound.play(SystemSoundType.alert);
      _fixtureNumberController.text = '';

      return;
    }

    _fixtureNumberController.text = '';
    if (_listScrollController.hasClients) {
      _listScrollController.jumpTo(
        _listScrollController.position.maxScrollExtent +
            _kMappingListItemExtent,
      );
    }

    final newSequenceNumber = _currentSequenceNumber + 1;
    _seqNumberController.text = newSequenceNumber.toString();

    setState(() {
      _mapping[_currentSequenceNumber] = fixture;
      _currentSequenceNumber = newSequenceNumber;
      _error = '';
    });
  }

  void _unassignFixture(FixtureModel fixture) {
    final entry = _mapping.entries.firstWhereOrNull(
      (entry) => entry.value.uid == fixture.uid,
    );
    if (entry == null) {
      return;
    }

    setState(() {
      _mapping = Map<int, FixtureModel>.from(_mapping)..remove(entry.key);
    });
  }

  @override
  void dispose() {
    _fixtureNumberController.dispose();
    _seqNumberController.dispose();
    _listScrollController.dispose();

    _fixtureNumberFocusNode.dispose();
    _sequenceNumberFocusNode.dispose();
    super.dispose();
  }
}

/// Segmented toggle switching the fixtures pane between the flat list and the
/// spatial plan view. The plan segment is disabled without position data.
class _ViewModeToggle extends StatelessWidget {
  final _FixtureViewMode mode;
  final bool planEnabled;
  final ValueChanged<_FixtureViewMode> onChanged;

  const _ViewModeToggle({
    required this.mode,
    required this.planEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimpleTooltip(
          message: 'List view',
          child: _segment(
            icon: Icons.view_list,
            selected: mode == _FixtureViewMode.list,
            enabled: true,
            onTap: () => onChanged(_FixtureViewMode.list),
          ),
        ),
        const SizedBox(width: 4),
        SimpleTooltip(
          message: planEnabled
              ? 'Plan view'
              : 'No position data for this selection',
          child: _segment(
            icon: Icons.scatter_plot,
            selected: mode == _FixtureViewMode.plan,
            enabled: planEnabled,
            onTap: () => onChanged(_FixtureViewMode.plan),
          ),
        ),
      ],
    );
  }

  Widget _segment({
    required IconData icon,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    if (selected) {
      return IconButton.primary(icon: Icon(icon), onPressed: onTap);
    }
    return IconButton.outline(
      icon: Icon(icon),
      onPressed: enabled ? onTap : null,
    );
  }
}

/// Spatial sort control for the unassigned list: an axis picker plus an
/// ascending/descending direction toggle. Axis options require position data.
class _SortControl extends StatelessWidget {
  final FixtureSortAxis axis;
  final bool descending;
  final bool hasCoords;
  final ValueChanged<FixtureSortAxis> onAxisChanged;
  final VoidCallback onToggleDirection;

  const _SortControl({
    required this.axis,
    required this.descending,
    required this.hasCoords,
    required this.onAxisChanged,
    required this.onToggleDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimpleTooltip(
          message: hasCoords ? null : 'No position data for this selection',
          child: SizedBox(
            width: 150,
            child: Select<FixtureSortAxis>(
              value: axis,
              onChanged: hasCoords
                  ? (value) => value == null ? null : onAxisChanged(value)
                  : null,
              itemBuilder: (context, item) => Text(_axisLabel(item)),
              popup: SelectPopup(
                items: SelectItemList(
                  children: FixtureSortAxis.values
                      .map(
                        (a) => SelectItemButton(
                          value: a,
                          child: Text(_axisLabel(a)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SimpleTooltip(
          message: descending ? 'Descending' : 'Ascending',
          child: IconButton.ghost(
            icon: Icon(descending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: onToggleDirection,
          ),
        ),
      ],
    );
  }

  String _axisLabel(FixtureSortAxis axis) => switch (axis) {
    FixtureSortAxis.selectionOrder => 'As selected',
    FixtureSortAxis.x => 'X (L→R)',
    FixtureSortAxis.y => 'Y (T→B)',
  };
}
