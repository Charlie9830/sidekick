import 'package:flutter/material.dart';
import 'package:sidekick/drag_overlay_region/drag_overlay_region.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';

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
        body: DragProxyController(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DraggableProxy<String>(
                  feedback: const Material(child: Text('Dragging')),
                  data: 'Hello',
                  child:
                      Container(width: 200, height: 200, color: Colors.purple)),
              Expanded(
                child: DragOverlayRegion(
                  childWhenDraggingOver: Container(
                    color: Colors.purple.withAlpha(60),
                    alignment: Alignment.center,
                    child: const _LandingPad(
                      color: Colors.orange,
                      size: 300,
                      name: 'Orange',
                    ),
                  ),
                  child: const _TestChild(),
                ),
              ),
            ],
          ),
        ));
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
