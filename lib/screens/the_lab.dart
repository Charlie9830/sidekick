import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/drag_overlay_region/drag_overlay_region.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/utils/get_uid.dart';

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
                      index: index,
                      child: Icon(Icons.place)),
                ),
              )
              .toList(),
          onReorder: (oldIndex, newIndex) {},
        ));
  }
}
