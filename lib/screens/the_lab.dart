import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  @override
  Widget build(BuildContext context) {
    final items = List<String>.generate(100, (index) => 'Item ${index + 1}');

    return Scaffold(
        appBar: AppBar(
          title: const Text('The Lab'),
          backgroundColor: Colors.red,
        ),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          children: items
              .mapIndexed(
                (index, item) => ListTile(
                  key: Key(item),
                  title: Text(item),
                  trailing: ReorderableDragStartListener(
                      index: index, child: const Icon(Icons.place)),
                ),
              )
              .toList(),
          onReorder: (oldIndex, newIndex) {},
        ));
  }
}
