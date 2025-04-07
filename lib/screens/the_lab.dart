import 'package:flutter/material.dart';
import 'package:sidekick/drag_overlay_region/drag_overlay_region.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/copy_with_inserted_entry.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/utils/get_uid.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('The Lab'),
          backgroundColor: Colors.red,
        ),
        body: Center(
            child: ElevatedButton(
          child: Text('Test'),
          onPressed: _doTest,
        )));
  }

  void _doTest() {
    final items = List<Item>.generate(
        10, (index) => Item(uid: getUid(), value: index + 1));

    final mapOfItems = Map<String, Item>.fromEntries(
        items.map((item) => MapEntry(item.uid, item)));

    printItemValues(mapOfItems);

    final withItemInserted = mapOfItems.copyWithInsertedEntry(
        2, MapEntry('Inserted', Item(uid: getUid(), value: 69)));

    printItemValues(withItemInserted);
  }

  void printItemValues(Map<String, Item> items) {
    for (var item in items.values) {
      print(item.toString());
    }
  }
}

class Item {
  final String uid;
  final int value;

  Item({
    required this.uid,
    required this.value,
  });

  @override
  String toString() {
    return value.toString();
  }
}

class _TestChild extends StatelessWidget {
  const _TestChild({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: List<Widget>.generate(
            5, (index) => ListTile(title: Text("Item ${index + 1}"))));
  }
}

class _LandingPad extends StatelessWidget {
  final Color color;
  final double size;
  final String name;

  final HitTestBehavior behaviour;

  const _LandingPad({
    super.key,
    required this.color,
    required this.name,
    required this.size,
    this.behaviour = HitTestBehavior.translucent,
  });

  @override
  Widget build(BuildContext context) {
    return DragTargetProxy(
        hitTestBehavior: behaviour,
        builder: (context, candidateData, rejectedData) {
          if (candidateData.isNotEmpty) {
            print(name);
          }
          return Container(
            alignment: Alignment.center,
            width: size,
            height: size,
            color: color,
          );
        });
  }
}
