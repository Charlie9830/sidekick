import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/sequencer_dialog/arrowed_divider.dart';
import 'package:sidekick/widgets/blur_listener.dart';

const double _kMappingListItemExtent = 56;

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
    _sequenceNumberFocusNode = FocusNode(onKeyEvent: ((node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
        _fixtureNumberFocusNode.requestFocus();
        return KeyEventResult.skipRemainingHandlers;
      }
      return KeyEventResult.ignored;
    }));

    _fixtureNumberFocusNode = FocusNode(onKeyEvent: ((node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
        _sequenceNumberFocusNode.requestFocus();
        return KeyEventResult.skipRemainingHandlers;
      }
      return KeyEventResult.ignored;
    }));

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
    final sortedAssignedFixtures =
        sortedSequenceKeys.map((seq) => (seq, _mapping[seq]!)).toList();

    final assignedIds =
        sortedAssignedFixtures.map((tuple) => tuple.$2.uid).toSet();

    final unassignedFixtures = _fixtures
        .where((fixture) => assignedIds.contains(fixture.uid) == false)
        .toList();

    return Dialog(
      child: SizedBox(
        width: 1366,
        height: 800,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Toolbar
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ]),

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
                                Text('Fixtures',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                IconButton(
                                  icon: const Icon(Icons.sort),
                                  onPressed: () =>
                                      _handleSortUnassignedPressed(),
                                )
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: unassignedFixtures.length,
                                itemBuilder: (context, index) {
                                  final fixture = unassignedFixtures[index];

                                  return ListTile(
                                    key: Key(fixture.uid),
                                    title: Text('#${fixture.fid.toString()}'),
                                    trailing: Text(widget
                                            .fixtureTypes[fixture.typeId]
                                            ?.name ??
                                        ''),
                                  );
                                },
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
                              OutlinedButton.icon(
                                label: const Text('Assign all'),
                                icon: const Icon(
                                    Icons.keyboard_double_arrow_right),
                                onPressed: unassignedFixtures.isNotEmpty
                                    ? () => _assignRemaining(unassignedFixtures)
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                label: const Text('Remove All'),
                                icon: const Icon(
                                    Icons.keyboard_double_arrow_left),
                                onPressed: _mapping.values.isNotEmpty
                                    ? () => setState(() => _mapping.clear())
                                    : null,
                              ),
                              Row(
                                children: [
                                  Tooltip(
                                    message: "Round Robin Assign",
                                    child: IconButton(
                                        icon: const Icon(
                                            Icons.roundabout_right_rounded),
                                        onPressed: unassignedFixtures.isNotEmpty
                                            ? () => _roundRobinAssign(
                                                unassignedFixtures)
                                            : null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 64),
                              Row(
                                children: [
                                  const Text('Sequence Number'),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 164,
                                    child: BlurListener(
                                      onBlur: _updateSequenceNumber,
                                      child: TextField(
                                        focusNode: _sequenceNumberFocusNode,
                                        controller: _seqNumberController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                        textAlign: TextAlign.center,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onEditingComplete:
                                            _updateSequenceNumber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Tooltip(
                                      message: 'Next Available',
                                      child: IconButton(
                                        icon: const Icon(Icons.fast_forward),
                                        onPressed: () =>
                                            _handleFindNextAvailableSequenceNumberPressed(),
                                      ))
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Text('Fixture Number'),
                                  const SizedBox(width: 36),
                                  SizedBox(
                                    width: 212,
                                    child: TextField(
                                      focusNode: _fixtureNumberFocusNode,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        errorText:
                                            _error.isEmpty ? null : _error,
                                      ),
                                      controller: _fixtureNumberController,
                                      textAlign: TextAlign.center,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onEditingComplete: () => _enumerate(),
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
                            Text('Assigned Fixtures',
                                style: Theme.of(context).textTheme.labelLarge),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemExtent: _kMappingListItemExtent,
                                controller: _listScrollController,
                                itemCount: sortedAssignedFixtures.length,
                                itemBuilder: (context, index) {
                                  final (seq, fixture) =
                                      sortedAssignedFixtures[index];
                                  return ListTile(
                                    leading: Text(seq.toString()),
                                    title: Text('#${fixture.fid.toString()}'),
                                    trailing: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(widget.fixtureTypes[fixture.typeId]
                                                ?.name ??
                                            ''),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.grey),
                                          iconSize: 16,
                                          onPressed: () {
                                            setState(() {
                                              _mapping =
                                                  Map<int, FixtureModel>.from(
                                                      _mapping)
                                                    ..remove(seq);
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(_mapping),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleSortUnassignedPressed() {
    setState(() {
      _fixtures = _fixtures.reversed.toList();
    });
  }

  void _handleFindNextAvailableSequenceNumberPressed() {
    setState(() {
      _currentSequenceNumber = widget.nextAvailableSequenceNumber;
      _seqNumberController.text = widget.nextAvailableSequenceNumber.toString();
    });
  }

  void _roundRobinAssign(List<FixtureModel> unassignedFixtures) {
    final fixturesByType =
        unassignedFixtures.groupListsBy((element) => element.typeId);
    final fixtureQueues = fixturesByType.entries
        .map((entry) => Queue<FixtureModel>.from(entry.value))
        .toList();

    final Map<int, FixtureModel> mapping = {};
    int mappingIndex = 0;
    int queueIndex = 0;

    while (fixtureQueues.any((queue) => queue.isNotEmpty)) {
      final currentQueue = fixtureQueues[queueIndex];

      if (currentQueue.isNotEmpty) {
        mapping[_currentSequenceNumber + mappingIndex] =
            currentQueue.removeFirst();

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
        (index, fixture) => MapEntry(_currentSequenceNumber + index, fixture));

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

    // Check if fixture as already been assigned.
    final duplicateFixtureEntry = _mapping.entries
        .firstWhereOrNull((entry) => entry.value.uid == fixture.uid);
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
    _listScrollController.jumpTo(
        _listScrollController.position.maxScrollExtent +
            _kMappingListItemExtent);

    final newSequenceNumber = _currentSequenceNumber + 1;
    _seqNumberController.text = newSequenceNumber.toString();

    setState(() {
      _mapping[_currentSequenceNumber] = fixture;
      _currentSequenceNumber = newSequenceNumber;
      _error = '';
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
