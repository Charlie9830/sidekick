import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/screens/looms/drag_data.dart';

class LandingPad extends StatefulWidget {
  final Widget icon;
  final String title;
  final bool enabled;
  final Widget? infoTag;

  final void Function(DragData data) onAccept;
  final bool Function(DragData onWillAccept) onWillAccept;

  const LandingPad({
    super.key,
    required this.icon,
    required this.title,
    required this.onAccept,
    required this.onWillAccept,
    this.infoTag,
    this.enabled = true,
  });

  @override
  State<LandingPad> createState() => _LandingPadState();
}

class _LandingPadState extends State<LandingPad> {
  bool _isHoveringOver = false;
  bool _isAccepting = true;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 128,
        height: 128,
        margin: const EdgeInsets.all(8),
        child: DragTargetProxy<DragData>(
          builder: (BuildContext context, List<DragData?> candidateData,
              List<dynamic> rejectedData) {
            return Card(
              elevation: 10,
              color: _resolveColor(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.icon,
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (widget.infoTag != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: widget.infoTag!,
                    )
                ],
              ),
            );
          },
          onAcceptWithDetails: (details) {
            setState(() {
              _isHoveringOver = false;
              _isAccepting = true;
            });
            widget.onAccept(details.data);
          },
          onWillAcceptWithDetails: (details) {
            final resolvedWillAccept = widget.onWillAccept(details.data);

            setState(() {
              _isHoveringOver = true;
              _isAccepting = resolvedWillAccept;
            });

            return widget.enabled && _isAccepting;
          },
          onLeave: (details) => setState(() {
            _isHoveringOver = false;
            _isAccepting = true;
          }),
        ));
  }

  Color? _resolveColor() {
    return _isHoveringOver && widget.enabled && _isAccepting
        ? Theme.of(context).buttonTheme.colorScheme!.inversePrimary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}
