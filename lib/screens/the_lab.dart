// ignore_for_file: public_member_api_docs, sort_constructors_first
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
  late Map<String, ItemContainer> _containers;
  late Map<String, Item> _items;
  late final AssignableItemListController<String, Item> _listController;

  @override
  void initState() {
    _items = {
      'item1': Item('item1'),
      'item2': Item('item2'),
      'item3': Item('item3'),
      'item4': Item('item4'),
      'item5': Item('item5'),
    };

    _containers = {
      'container1':
          ItemContainer(name: 'Container 1', uid: 'container1', slots: [
        ItemAssignmentReference(index: 0, itemId: 'item1'),
        ItemAssignmentReference(index: 1, itemId: 'item2'),
        ItemAssignmentReference(index: 2, itemId: 'item3'),
        ItemAssignmentReference(index: 3, itemId: ''),
        ItemAssignmentReference(index: 4, itemId: ''),
        ItemAssignmentReference(index: 5, itemId: ''),
        ItemAssignmentReference(index: 6, itemId: ''),
        ItemAssignmentReference(index: 7, itemId: ''),
      ]),
    };

    _listController = AssignableItemListController<String, Item>(
      items: _toAssignableItems(_items),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LabViewModel>(
      converter: (store) => LabViewModel(
        store: store,
      ),
      builder: (context, viewModel) {
        final containers = _containers.values.toList();
        final itemKeys = _listController.items.keys.toList();

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
            child: DefaultAssignableItemListController<String, Item>(
              controller: _listController,
              child: Row(
                children: [
                  SizedBox(
                      width: 400,
                      child: Card(
                          child: ReorderableList(
                        itemCount: itemKeys.length,
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }

                          final movingItemId = itemKeys.removeAt(oldIndex);
                          itemKeys.insert(newIndex, movingItemId);

                          final updatedItems = Map<String, Item>.fromEntries(
                              itemKeys
                                  .map((key) => MapEntry(key, _items[key]!)));

                          setState(() {
                            _items = updatedItems;
                          });

                          _listController
                              .updateItems(_toAssignableItems(updatedItems));
                        },
                        itemBuilder: (context, index) {
                          final itemId = itemKeys[index];

                          return Row(
                            key: Key(itemId),
                            children: [
                              SizedBox(
                                width: 24,
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_handle),
                                ),
                              ),
                              Expanded(
                                child: CandidateDelegate<String, Item>(
                                  id: itemId,
                                  fallbackController: _listController,
                                  builder: (context, item, isSelected) {
                                    return Container(
                                        height: 32,
                                        alignment: Alignment.centerLeft,
                                        color: isSelected ? Colors.gray : null,
                                        child: Text(item?.item.name ?? 'Null'));
                                  },
                                  selectionIndex: index,
                                ),
                              ),
                            ],
                          );
                        },
                      ))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: containers.length,
                      itemBuilder: (context, index) {
                        final itemContainer = containers[index];

                        return Column(
                          children: itemContainer.slots
                              .mapIndexed(
                                (index, slot) => ItemSlot<String, Item>(
                                  onItemsLanded: (ids) {
                                    final landingIndex = slot.index;

                                    final itemSlots =
                                        itemContainer.slots.toList();

                                    final movingIds = ids.toSet();

                                    itemSlots.removeWhere((slot) =>
                                        movingIds.contains(slot.itemId));

                                    itemSlots.addAll(ids.mapIndexed(
                                        (offsetIndex, id) =>
                                            ItemAssignmentReference(
                                                index:
                                                    offsetIndex + landingIndex,
                                                itemId: id)));

                                    final updatedContainers =
                                        Map<String, ItemContainer>.from(
                                            _containers)
                                          ..update(
                                              itemContainer.uid,
                                              (value) => value.copyWith(
                                                    slots: itemSlots,
                                                  ));

                                    setState(
                                        () => _containers = updatedContainers);
                                  },
                                  assignedItemId:
                                      slot.itemId.isEmpty ? null : slot.itemId,
                                  slotIndex: index,
                                  slotIndexScope: itemContainer.uid,
                                  selectionIndex: index,
                                  builder: (context, value, isSelected) {
                                    return Container(
                                      height: 48,
                                      color: isSelected ? Colors.gray : null,
                                      child: Row(
                                        children: [
                                          Text('$index'),
                                          const VerticalDivider(width: 36),
                                          value == null
                                              ? SizedBox()
                                              : Text(value.item.name),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  )
                ],
              ),
            ));
      },
    );
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Map<String, AssignableItem<String, Item>> _toAssignableItems(
      Map<String, Item> items) {
    return items.map(
      (key, value) => MapEntry(
        key,
        AssignableItem<String, Item>(id: key, item: value),
      ),
    );
  }
}

class Item {
  final String uid;
  final String name;

  Item(this.uid) : name = uid;
}

class ItemContainer {
  final String uid;
  final String name;
  final List<ItemAssignmentReference> slots;

  ItemContainer({
    required this.uid,
    required this.name,
    required this.slots,
  });

  ItemContainer copyWith({
    String? uid,
    String? name,
    List<ItemAssignmentReference>? slots,
  }) {
    return ItemContainer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      slots: slots ?? this.slots,
    );
  }
}

class ItemAssignmentReference {
  final int index;
  final String itemId;

  ItemAssignmentReference({
    required this.index,
    required this.itemId,
  });
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
