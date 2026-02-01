import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';

class ListTester extends StatefulWidget {
  const ListTester({super.key});

  @override
  State<ListTester> createState() => _ListTesterState();
}

class _ListTesterState extends State<ListTester> {
  Map<String, Item> _items = {
    'id 1': Item('id 1', 'Item 1'),
    'id 2': Item('id 2', 'Item 2'),
    'id 3': Item('id 3', 'Item 3'),
    'id 4': Item('id 4', 'Item 4'),
  };

  @override
  Widget build(BuildContext context) {
    return AssignableItemListController<String, Item>(
        items: Map<String, CandidateValue<String, Item>>.fromEntries(
            _items.values.mapIndexed((index, item) => MapEntry(item.uid,
                CandidateValue(id: item.uid, index: index, value: item)))),
        child: Row(
          children: [
            // Sidebar
            Column(
                children: _items.values
                    .map((item) => UnassignedItem<String, Item>(
                        id: item.uid,
                        builder: (context, value) =>
                            value == null ? Text('-') : Text(value.value.name)))
                    .toList()),
            VerticalDivider(width: 24),
            // Column
            Column(
              children: List.generate(
                  8,
                  (index) => Slot<String, Item>(
                        itemAssignmentId: 'id ${index + 1}',
                        builder: (context, value) {
                          return Row(
                            children: [
                              Text((index + 1).toString(),
                                  style: Theme.of(context).typography.mono),
                              SizedBox(width: 16),
                              if (value != null) Text(value.value.name),
                            ],
                          );
                        },
                      )),
            ),

            TextButton(
                child: Text('Test'),
                onPressed: () {
                  setState(() {
                    _items = _items
                      ..clone()
                      ..addAll({'id 5': Item('id 5', 'Item 5')});
                  });
                })
          ],
        ));
  }
}

class Item extends ModelCollectionMember {
  @override
  final String uid;
  final String name;

  Item(this.uid, this.name);
}

///
/// Orchestrates Selection and Drag and Drop utilities for Decendant Assignable List Items.
/// Accepts a Map<K, CandidateValue<K,V> where K is the type of the ID used and V is the item specific Value.
///
class AssignableItemListController<K, V> extends StatelessWidget {
  final Map<K, CandidateValue<K, V>> items;
  final Widget child;

  const AssignableItemListController(
      {super.key, required this.items, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListControllerMessenger<K, V>(items: items, child: child);
  }
}

class CandidateValue<K, V> {
  final K id;
  final V value;
  final int index;

  CandidateValue({
    required this.id,
    required this.value,
    required this.index,
  });
}

class ListControllerMessenger<K, V> extends InheritedWidget {
  final Map<K, CandidateValue<K, V>> items;

  const ListControllerMessenger(
      {super.key, required super.child, required this.items});

  static ListControllerMessenger? maybeOf<K, V>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<ListControllerMessenger<K, V>>();
  }

  @override
  bool updateShouldNotify(covariant ListControllerMessenger oldWidget) {
    return oldWidget.items != items;
  }

  CandidateValue<K, V>? fetchValue(K id) {
    return items[id];
  }
}

typedef CandidateBuilder<K, V> = Widget Function(
    BuildContext context, CandidateValue<K, V>? value);

class UnassignedItem<K, V> extends StatelessWidget {
  final K id;
  final CandidateBuilder<K, V> builder;

  const UnassignedItem({super.key, required this.id, required this.builder});

  @override
  Widget build(BuildContext context) {
    final candidateValue =
        ListControllerMessenger.maybeOf<K, V>(context)?.fetchValue(id);
    return builder(context, candidateValue as CandidateValue<K, V>?);
  }
}

class Slot<K, V> extends StatelessWidget {
  final K? itemAssignmentId;
  final CandidateBuilder<K, V> builder;

  const Slot({
    super.key,
    required this.itemAssignmentId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final candidateValue = ListControllerMessenger.maybeOf<K, V>(context)
        ?.fetchValue(itemAssignmentId);
    return builder(context, candidateValue as CandidateValue<K, V>?);
  }
}
