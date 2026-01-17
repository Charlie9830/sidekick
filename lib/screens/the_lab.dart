import 'package:collection/collection.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/item_selection/get_item_selection_index_closure.dart';
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

  Set<String> _selectedCandidateItemIds = {};
  Set<String> _selectedSlottedItemIds = {};

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
      builder: (context, viewModel) {
        final getCandidateSelectionIndex = getItemSelectionIndexClosure();
        final getSlottedItemSelectionIndex = getItemSelectionIndexClosure();

        return Scaffold(
            headers: [
              AppBar(
                title: const Text('The Lab'),
                backgroundColor: Colors.orange.shade600,
              ),
            ],
            child: SlottedListController(
              selectedCandidateIds: _selectedCandidateItemIds,
              selectedSlottedItemIds: _selectedSlottedItemIds,
              onSelectedCandidateIdsChanged: (ids) => setState(() {
                _selectedCandidateItemIds = ids;
                _selectedSlottedItemIds = {};
              }),
              onSelectedSlottedItemIdsChanged: (ids) => setState(() {
                _selectedSlottedItemIds = ids;
                _selectedCandidateItemIds = {};
              }),
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

                          final item = _items.values.toList()[index];

                          return CandidateListItem(
                            data: CandidateData(
                                itemId: item.id,
                                candidateSelectionIndex:
                                    getCandidateSelectionIndex(),
                                slottedSelectionIndex: _assignments.values
                                    .toList()
                                    .indexOf(item.id),
                                candidateBuilder: (context, itemId) => Card(
                                    filled: true,
                                    fillColor: _selectedCandidateItemIds
                                            .contains(item.id)
                                        ? Colors.gray
                                        : null,
                                    child: Text(_items[itemId]!.name)),
                                slottedContentsBuilder: (context, itemId) =>
                                    Row(
                                      spacing: 12,
                                      children: [
                                        Text(_items[itemId]!.name),
                                        const Icon(
                                            Icons.sentiment_very_satisfied,
                                            color: Colors.green)
                                      ],
                                    )),
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
                              builder: (context, slotIndex, child, selected) =>
                                  Card(
                                      filled: true,
                                      fillColor: selected ? Colors.gray : null,
                                      child: SizedBox(
                                        height: 24,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                                width: 48,
                                                child: Text(
                                                    (index + 1).toString(),
                                                    style: Theme.of(context)
                                                        .typography
                                                        .p)),
                                            const VerticalDivider(width: 24),
                                            child ?? const Text('---'),
                                          ],
                                        ),
                                      )),
                            );
                          }))
                ],
              ),
            ));
      },
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
