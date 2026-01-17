import 'package:collection/collection.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/slotted_list/slotted_list.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  final Map<String, Item> _items = List<Item>.generate(
          24, (index) => Item((index + 1).toString(), "Item ${index + 1}"))
      .toModelMap();

  final Map<int, String> _assignments = {};

  @override
  void initState() {
    _assignments.addEntries(_items.values
        .take(4)
        .mapIndexed((index, item) => MapEntry(index, item.id)));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LabViewModel>(
      converter: (store) => LabViewModel(
        store: store,
      ),
      builder: (context, viewModel) => Scaffold(
          headers: [
            AppBar(
              title: const Text('The Lab'),
              backgroundColor: Colors.orange.shade600,
            ),
          ],
          child: SlottedListController(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 400,
                  child: Card(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return null;
                        }
                        return Card(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.popover,
                          child: CandidateListItem(
                            data: CandidateData(
                                itemId: _items.values.toList()[index]!.id,
                                candidateBuilder: (context, itemId) =>
                                    Text(_items[itemId]!.name),
                                slottedBuilder: (context, itemId) => Row(
                                      spacing: 12,
                                      children: [
                                        Text(_items[itemId]!.name),
                                        const Icon(
                                            Icons.sentiment_very_satisfied,
                                            color: Colors.green)
                                      ],
                                    )),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: 24,
                        itemBuilder: (context, index) {
                          return Slot(
                            assignedItemId: _assignments[index],
                            index: index,
                            builder: (context, slotIndex, child) => Card(
                                child: SizedBox(
                              height: 24,
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: 48,
                                      child: Text((index + 1).toString(),
                                          style:
                                              Theme.of(context).typography.p)),
                                  const VerticalDivider(width: 24),
                                  child ?? const Text('---'),
                                ],
                              ),
                            )),
                          );
                        }))
              ],
            ),
          )),
    );
  }
}

class Item extends ModelCollectionMember {
  final String id;
  final String name;

  Item(this.id, this.name);

  @override
  String get uid => id;
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
