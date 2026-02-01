import 'package:collection/collection.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/slotted_list/attempt2.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  Map<String, Item> _items = {};

  Set<String> _selectedCandidateIds = {};
  Set<String> _selectedAssignedIds = {};

  @override
  void initState() {
    _items = Map<String, Item>.fromEntries(List.generate(
        100, (index) => MapEntry('id $index', Item('id $index'))));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final itemList = _items.values.toList();

    return StoreConnector<AppState, LabViewModel>(
      converter: (store) => LabViewModel(
        store: store,
      ),
      builder: (context, viewModel) {
        return Scaffold(
            headers: [
              AppBar(
                title: const Text('The Lab'),
                backgroundColor: Colors.emerald,
                trailing: [
                  PrimaryButton(
                    child: const Text('Debug Action'),
                    onPressed: () =>
                        viewModel.store.dispatch(debugButtonPressed()),
                  )
                ],
              ),
            ],
            child: AssignableItemListController<String, Item>(
              items: Map<String, AssignableItem<String, Item>>.fromEntries(
                _items.values.mapIndexed(
                  (index, item) => MapEntry(
                    item.uid,
                    AssignableItem<String, Item>(
                        candidateSelectionIndex: index,
                        assignedSelectionIndex: null,
                        id: item.uid,
                        item: item),
                  ),
                ),
              ),
              onSelectedCandidateIdsChanged: (ids) =>
                  setState(() => _selectedCandidateIds = ids),
              onSelectedAssignedIdsChanged: (ids) =>
                  setState(() => _selectedAssignedIds = ids),
              selectedAssignedItemIds: _selectedAssignedIds,
              selectedCandidateItemIds: _selectedCandidateIds,
              child: Row(
                children: [
                  SizedBox(
                      width: 300,
                      child: ListView.builder(
                          itemCount: itemList.length,
                          itemBuilder: (context, index) {
                            final item = itemList[index];
                            return CandidateItem<String, Item>(
                                id: item.uid,
                                builder: (context, item, selected) => Card(
                                    filled: true,
                                    fillColor: selected ? Colors.gray : null,
                                    child: Text(item?.item.name ?? '-')));
                          })),
                  VerticalDivider(width: 24),
                  Column(
                    children: [],
                  )
                ],
              ),
            ));
      },
    );
  }
}

class Item {
  final String uid;
  final String name;

  Item(this.uid) : name = uid;
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
