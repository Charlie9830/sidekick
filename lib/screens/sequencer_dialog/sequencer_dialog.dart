import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/screens/sequencer_dialog/titled_card.dart';
import 'package:sidekick/widgets/blur_listener.dart';

const double _kMappingListItemExtent = 56;

class SequencerDialog extends StatefulWidget {
  final List<FixtureModel> fixtures;

  const SequencerDialog({
    Key? key,
    required this.fixtures,
  }) : super(key: key);

  @override
  State<SequencerDialog> createState() => _SequencerDialogState();
}

class _SequencerDialogState extends State<SequencerDialog> {
  int _currentSequenceNumber = 1;
  Map<int, FixtureModel> _mapping = {};
  late final TextEditingController _fixtureNumberController;
  late final TextEditingController _seqNumberController;
  late final ScrollController _listScrollController;
  String _error = '';

  @override
  void initState() {
    super.initState();

    _fixtureNumberController = TextEditingController();
    _seqNumberController = TextEditingController(text: 1.toString());
    _listScrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final sortedSequenceKeys = _mapping.keys.sorted((a, b) => a - b);
    final sortedAssignedFixtures =
        sortedSequenceKeys.map((seq) => (seq, _mapping[seq]!)).toList();

    final assignedIds =
        sortedAssignedFixtures.map((tuple) => tuple.$2.uid).toSet();

    final unassignedFixtures = widget.fixtures
        .where((fixture) => assignedIds.contains(fixture.uid) == false)
        .toList();

    return Dialog(
      child: SizedBox(
        width: 1200,
        height: 800,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TitledCard(
                          title: 'Fixtures',
                          child: ListView.builder(
                            itemCount: unassignedFixtures.length,
                            itemBuilder: (context, index) {
                              final fixture = unassignedFixtures[index];

                              return ListTile(
                                key: Key(fixture.uid),
                                title: Text('#${fixture.fid.toString()}'),
                                trailing: Text(fixture.type.name),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        child: TitledCard(
                          title: '',
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Text('Sequence Number'),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 120,
                                      child: BlurListener(
                                        onBlur: _updateSequenceNumber,
                                        child: TextField(
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
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text('Fixture Number'),
                                    const SizedBox(width: 36),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          errorText:
                                              _error.isEmpty ? null : _error,
                                        ),
                                        controller: _fixtureNumberController,
                                        textAlign: TextAlign.center,
                                        autofocus: true,
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
                      ),
                      Expanded(
                        child: TitledCard(
                          title: 'Assigned',
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
                                trailing: Text(fixture.type.name),
                              );
                            },
                          ),
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

  void _updateSequenceNumber() {
    setState(() {
      _currentSequenceNumber = int.tryParse(_seqNumberController.text) ?? 1;
    });
  }

  void _enumerate() {
    final fid = int.parse(_fixtureNumberController.text);
    final fixture = widget.fixtures.firstWhereOrNull((fix) => fix.fid == fid);

    if (fixture == null) {
      setState(() {
        _error = "#${_fixtureNumberController.text}: Unknown Fixture";
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
    super.dispose();
  }
}
