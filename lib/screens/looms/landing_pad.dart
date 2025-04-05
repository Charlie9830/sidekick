import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/drag_data.dart';

class LandingPad extends StatefulWidget {
  final Widget icon;
  final String title;
  
  final void Function(DragData data) onAccept;
  final bool Function(DragData onWillAccept) onWillAccept;

  const LandingPad({
    super.key,
    required this.icon,
    required this.title,
    required this.onAccept,
    required this.onWillAccept,
  });

  @override
  State<LandingPad> createState() => _LandingPadState();
}

class _LandingPadState extends State<LandingPad> {
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
          builder: (BuildContext context, List<DragData?> candidateData,
              List<dynamic> rejectedData) {
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
            return widget.onWillAccept(details.data);
          },
          onLeave: (details) => setState(() => _isHoveringOver = false),
        ));
  }
}
