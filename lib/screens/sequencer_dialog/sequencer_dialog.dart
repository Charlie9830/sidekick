import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/sequencer_dialog/arrowed_divider.dart';
import 'package:sidekick/screens/sequencer_dialog/fixture_spatial_sort.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_plan_view.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/widgets/property_field.dart';

const double _kMappingListItemExtent = 56;

/// Width of the central controls column in every layout.
const double _kControlsPaneWidth = 400;

/// How the unassigned fixtures are presented: a flat list or the spatial plot.
enum _FixtureViewMode { list, plan }

/// Where the rig (plan) view sits when it is visible: a full-height panel
/// down the left (default), or a full-width strip across the top for rigs
/// whose fixtures are laid out horizontally.
enum _RigViewPlacement { left, top }

/// Full-screen dialog for assigning sequence numbers to the selected
/// fixtures, either by typing fixture numbers or by clicking fixtures in the
/// rig (plan) view. Pops with the sequence → fixture mapping on Done.
class SequencerDialog extends StatefulWidget {
  final List<FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final Map<String, FixtureGeometryModel> fixtureGeometries;
  final int nextAvailableSequenceNumber;

  const SequencerDialog({
    super.key,
    required this.fixtures,
    required this.fixtureTypes,
    required this.fixtureGeometries,
    required this.nextAvailableSequenceNumber,
  });

  @override
  State<SequencerDialog> createState() => _SequencerDialogState();
}

class _SequencerDialogState extends State<SequencerDialog> {
  int _currentSequenceNumber = 1;
  Map<int, FixtureModel> _mapping = {};
  late List<FixtureModel> _fixtures;
  _FixtureViewMode _viewMode = _FixtureViewMode.list;
  _RigViewPlacement _rigPlacement = _RigViewPlacement.left;
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
    final planMode = _viewMode == _FixtureViewMode.plan && hasCoords;

    return SizedBox.expand(
      child: Card(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogHeader(
              viewMode: _viewMode,
              planEnabled: hasCoords,
              rigPlacement: _rigPlacement,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              onRigPlacementChanged: (placement) =>
                  setState(() => _rigPlacement = placement),
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: planMode
                    ? _buildPlanBody(unassignedFixtures, sortedAssignedFixtures)
                    : _buildListBody(
                        unassignedFixtures,
                        sortedAssignedFixtures,
                        hasCoords,
                      ),
              ),
            ),
            const Divider(),
            _Footer(
              assignedCount: _mapping.length,
              totalCount: _fixtures.length,
              onDone: () => Navigator.of(context).pop(_mapping),
            ),
          ],
        ),
      ),
    );
  }

  /// Three columns: unassigned list, controls, assigned list. Capped in width
  /// and centered so the lists stay readable on wide displays.
  Widget _buildListBody(
    List<FixtureModel> unassignedFixtures,
    List<(int, FixtureModel)> assignedFixtures,
    bool hasCoords,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _UnassignedListPane(
                fixtures: unassignedFixtures,
                fixtureTypes: widget.fixtureTypes,
                sortAxis: _sortAxis,
                sortDescending: _sortDescending,
                hasCoords: hasCoords,
                onAxisChanged: (axis) => _applySort(axis: axis),
                onToggleDirection: () =>
                    _applySort(descending: !_sortDescending),
              ),
            ),
            const ArrowedDivider(),
            SizedBox(
              width: _kControlsPaneWidth,
              child: _buildControlsPane(unassignedFixtures),
            ),
            const ArrowedDivider(),
            Expanded(child: _buildAssignedPane(assignedFixtures)),
          ],
        ),
      ),
    );
  }

  /// Rig view layouts: a full-height panel down the left (default) or a
  /// full-width strip across the top, with the controls and assigned list
  /// arranged around it.
  Widget _buildPlanBody(
    List<FixtureModel> unassignedFixtures,
    List<(int, FixtureModel)> assignedFixtures,
  ) {
    final rigView = _RigViewPane(
      child: SequencerPlanView(
        fixtures: _fixtures,
        fixtureTypes: widget.fixtureTypes,
        fixtureGeometries: widget.fixtureGeometries,
        mapping: _mapping,
        onAssign: _assignFixtureToCurrentSequence,
        onUnassign: _unassignFixture,
      ),
    );

    final controls = SizedBox(
      width: _kControlsPaneWidth,
      child: _buildControlsPane(unassignedFixtures),
    );

    return switch (_rigPlacement) {
      _RigViewPlacement.left => Row(
        children: [
          Expanded(flex: 2, child: rigView),
          const ArrowedDivider(),
          controls,
          const ArrowedDivider(),
          Expanded(child: _buildAssignedPane(assignedFixtures)),
        ],
      ),
      _RigViewPlacement.top => Column(
        children: [
          Expanded(flex: 3, child: rigView),
          const ArrowedDivider(axis: Axis.horizontal),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                controls,
                const ArrowedDivider(),
                Expanded(child: _buildAssignedPane(assignedFixtures)),
              ],
            ),
          ),
        ],
      ),
    };
  }

  Widget _buildControlsPane(List<FixtureModel> unassignedFixtures) {
    return _ControlsPane(
      canAssign: unassignedFixtures.isNotEmpty,
      canRemoveAll: _mapping.isNotEmpty,
      error: _error,
      sequenceNumberController: _seqNumberController,
      fixtureNumberController: _fixtureNumberController,
      sequenceNumberFocusNode: _sequenceNumberFocusNode,
      fixtureNumberFocusNode: _fixtureNumberFocusNode,
      onSequenceNumberBlur: _updateSequenceNumber,
      onFixtureNumberBlur: _enumerate,
      onNextAvailable: _handleFindNextAvailableSequenceNumberPressed,
      onAssignAll: () => _assignRemaining(unassignedFixtures),
      onRemoveAll: () => setState(() => _mapping.clear()),
      onRoundRobin: () => _roundRobinAssign(unassignedFixtures),
    );
  }

  Widget _buildAssignedPane(List<(int, FixtureModel)> assignedFixtures) {
    return _AssignedListPane(
      assignedFixtures: assignedFixtures,
      fixtureTypes: widget.fixtureTypes,
      scrollController: _listScrollController,
      onRemove: (seq) {
        setState(() {
          _mapping = Map<int, FixtureModel>.from(_mapping)..remove(seq);
        });
      },
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

/// Title bar for the full-screen dialog: an explicit title on the left, the
/// list/plan toggle, the rig view placement toggle and the close button in
/// the top-right corner.
class _DialogHeader extends StatelessWidget {
  final _FixtureViewMode viewMode;
  final bool planEnabled;
  final _RigViewPlacement rigPlacement;
  final ValueChanged<_FixtureViewMode> onViewModeChanged;
  final ValueChanged<_RigViewPlacement> onRigPlacementChanged;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.viewMode,
    required this.planEnabled,
    required this.rigPlacement,
    required this.onViewModeChanged,
    required this.onRigPlacementChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        spacing: 8,
        children: [
          Text('Sequence Assignment', style: Theme.of(context).typography.h4),
          const Spacer(),
          _ViewModeToggle(
            mode: viewMode,
            planEnabled: planEnabled,
            onChanged: onViewModeChanged,
          ),
          _RigPlacementToggle(
            placement: rigPlacement,
            enabled: viewMode == _FixtureViewMode.plan && planEnabled,
            onChanged: onRigPlacementChanged,
          ),
          const SizedBox(height: 24, child: VerticalDivider()),
          IconButton.ghost(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

/// Footer with a running assignment count and the Done button.
class _Footer extends StatelessWidget {
  final int assignedCount;
  final int totalCount;
  final VoidCallback onDone;

  const _Footer({
    required this.assignedCount,
    required this.totalCount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '$assignedCount of $totalCount fixtures assigned',
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
          const Spacer(),
          PrimaryButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}

/// The unassigned fixtures as a sortable flat list with its pane header.
class _UnassignedListPane extends StatelessWidget {
  final List<FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final FixtureSortAxis sortAxis;
  final bool sortDescending;
  final bool hasCoords;
  final ValueChanged<FixtureSortAxis> onAxisChanged;
  final VoidCallback onToggleDirection;

  const _UnassignedListPane({
    required this.fixtures,
    required this.fixtureTypes,
    required this.sortAxis,
    required this.sortDescending,
    required this.hasCoords,
    required this.onAxisChanged,
    required this.onToggleDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fixtures', style: Theme.of(context).typography.lead),
            _SortControl(
              axis: sortAxis,
              descending: sortDescending,
              hasCoords: hasCoords,
              onAxisChanged: onAxisChanged,
              onToggleDirection: onToggleDirection,
            ),
          ],
        ),
        const Divider(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: fixtures.length,
            itemBuilder: (context, index) {
              final fixture = fixtures[index];

              return ShadListItem(
                key: Key(fixture.uid),
                title: Text('#${fixture.fid.toString()}'),
                trailing: Text(fixtureTypes[fixture.typeId]?.name ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The assigned fixtures in sequence order, each removable, with its pane
/// header.
class _AssignedListPane extends StatelessWidget {
  final List<(int, FixtureModel)> assignedFixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final ScrollController scrollController;
  final void Function(int sequenceNumber) onRemove;

  const _AssignedListPane({
    required this.assignedFixtures,
    required this.fixtureTypes,
    required this.scrollController,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assigned Fixtures', style: Theme.of(context).typography.lead),
        const Divider(height: 16),
        Expanded(
          child: ListView.builder(
            itemExtent: _kMappingListItemExtent,
            controller: scrollController,
            itemCount: assignedFixtures.length,
            itemBuilder: (context, index) {
              final (seq, fixture) = assignedFixtures[index];
              return ShadListItem(
                leading: Text(seq.toString()),
                title: Text('#${fixture.fid.toString()}'),
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fixtureTypes[fixture.typeId]?.name ?? ''),
                    IconButton.ghost(
                      icon: const Icon(Icons.remove_circle, color: Colors.gray),
                      onPressed: () => onRemove(seq),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The central controls: sequence and fixture number entry on top, bulk
/// assignment actions below. Scrolls if the pane is shorter than its content
/// (e.g. when the rig view strip is across the top).
class _ControlsPane extends StatelessWidget {
  final bool canAssign;
  final bool canRemoveAll;
  final String error;
  final TextEditingController sequenceNumberController;
  final TextEditingController fixtureNumberController;
  final FocusNode sequenceNumberFocusNode;
  final FocusNode fixtureNumberFocusNode;
  final VoidCallback onSequenceNumberBlur;
  final VoidCallback onFixtureNumberBlur;
  final VoidCallback onNextAvailable;
  final VoidCallback onAssignAll;
  final VoidCallback onRemoveAll;
  final VoidCallback onRoundRobin;

  const _ControlsPane({
    required this.canAssign,
    required this.canRemoveAll,
    required this.error,
    required this.sequenceNumberController,
    required this.fixtureNumberController,
    required this.sequenceNumberFocusNode,
    required this.fixtureNumberFocusNode,
    required this.onSequenceNumberBlur,
    required this.onFixtureNumberBlur,
    required this.onNextAvailable,
    required this.onAssignAll,
    required this.onRemoveAll,
    required this.onRoundRobin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: PropertyField(
                    focusNode: sequenceNumberFocusNode,
                    controller: sequenceNumberController,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    label: 'Sequence Number',
                    labelAlign: LabelAlign.center,
                    onBlur: (_) => onSequenceNumberBlur(),
                  ),
                ),
                SimpleTooltip(
                  message: 'Next Available',
                  child: IconButton.ghost(
                    icon: const Icon(Icons.fast_forward),
                    onPressed: onNextAvailable,
                  ),
                ),
              ],
            ),
            PropertyField(
              focusNode: fixtureNumberFocusNode,
              autofocus: true,
              error: error.isEmpty ? null : error,
              controller: fixtureNumberController,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              label: 'Fixture Number',
              labelAlign: LabelAlign.center,
              onBlur: (_) => onFixtureNumberBlur(),
              submitAction: PropertyFieldSubmitAction.none,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            OutlineButton(
              leading: const Icon(Icons.keyboard_double_arrow_right),
              onPressed: canAssign ? onAssignAll : null,
              child: const Text('Assign all'),
            ),
            OutlineButton(
              leading: const Icon(Icons.roundabout_right_rounded),
              onPressed: canAssign ? onRoundRobin : null,
              child: const Text('Round Robin Assign'),
            ),
            OutlineButton(
              leading: const Icon(Icons.keyboard_double_arrow_left),
              onPressed: canRemoveAll ? onRemoveAll : null,
              child: const Text('Remove All'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered container delineating the rig (plan) view from the surrounding
/// panes.
class _RigViewPane extends StatelessWidget {
  final Widget child;

  const _RigViewPane({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: theme.borderRadiusLg,
      ),
      child: child,
    );
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
      spacing: 4,
      children: [
        SimpleTooltip(
          message: 'List view',
          child: _ToggleSegment(
            icon: Icons.view_list,
            selected: mode == _FixtureViewMode.list,
            enabled: true,
            onTap: () => onChanged(_FixtureViewMode.list),
          ),
        ),
        SimpleTooltip(
          message: planEnabled
              ? 'Rig view'
              : 'No position data for this selection',
          child: _ToggleSegment(
            icon: Icons.scatter_plot,
            selected: mode == _FixtureViewMode.plan,
            enabled: planEnabled,
            onTap: () => onChanged(_FixtureViewMode.plan),
          ),
        ),
      ],
    );
  }
}

/// Segmented toggle choosing where the rig view sits: a panel down the left
/// or a strip across the top. Only active while the rig view is showing.
class _RigPlacementToggle extends StatelessWidget {
  final _RigViewPlacement placement;
  final bool enabled;
  final ValueChanged<_RigViewPlacement> onChanged;

  const _RigPlacementToggle({
    required this.placement,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        SimpleTooltip(
          message: enabled
              ? 'Rig view down the left'
              : 'Switch to the rig view to change its layout',
          child: _ToggleSegment(
            icon: Icons.vertical_split,
            selected: placement == _RigViewPlacement.left,
            enabled: enabled,
            onTap: () => onChanged(_RigViewPlacement.left),
          ),
        ),
        SimpleTooltip(
          message: enabled
              ? 'Rig view across the top'
              : 'Switch to the rig view to change its layout',
          child: _ToggleSegment(
            icon: Icons.horizontal_split,
            selected: placement == _RigViewPlacement.top,
            enabled: enabled,
            onTap: () => onChanged(_RigViewPlacement.top),
          ),
        ),
      ],
    );
  }
}

/// One segment of an icon toggle: primary when selected, outline otherwise.
class _ToggleSegment extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return IconButton.primary(
        icon: Icon(icon),
        onPressed: enabled ? onTap : null,
      );
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
              ).call,
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
