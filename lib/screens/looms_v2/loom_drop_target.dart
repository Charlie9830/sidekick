import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms_v2/drag_data.dart';

class LoomDropTarget extends StatefulWidget {
  final Widget icon;
  final String title;
  final void Function(DragData data) onAccept;
  const LoomDropTarget(
      {super.key,
      required this.icon,
      required this.title,
      required this.onAccept});

  @override
  State<LoomDropTarget> createState() => _LoomDropTargetState();
}

class _LoomDropTargetState extends State<LoomDropTarget> {
  bool _isHoveringOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 128,
        height: 128,
        margin: const EdgeInsets.all(8),
        color: _isHoveringOver ? Theme.of(context).focusColor : null,
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hoverColor, width: 5),
        ),
        child: DragTarget<DragData>(
          builder: (BuildContext context, List<DragData?> _, List<dynamic> __) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                Text(widget.title),
              ],
            );
          },
          onAcceptWithDetails: (details) {
            setState(() => _isHoveringOver = false);
            widget.onAccept(details.data);
          },
          onWillAcceptWithDetails: (details) {
            setState(() {
              _isHoveringOver = true;
            });
            return true;
          },
          onLeave: (details) => setState(() => _isHoveringOver = false),
        ));
  }
}
