import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/new_loom_drop_target_overlay.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class NoLoomsHoverFallback extends StatefulWidget {
  const NoLoomsHoverFallback({
    super.key,
    required this.onCreateNewLoom,
  });

  final void Function(List<OutletViewModel> outlets, CableActionModifier modifier) onCreateNewLoom;

  @override
  State<NoLoomsHoverFallback> createState() => _NoLoomsHoverFallbackState();
}

class _NoLoomsHoverFallbackState extends State<NoLoomsHoverFallback> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('To begin, drag outlets to here to create looms'),
        if (DragProxyMessenger.of(context)!.isDragging)
          NewLoomDropTargetOverlay(
            onDropAsFeeder: widget.onCreateNewLoom,
            onDropAsExtension:
                (_) {}, // Stubbed because the user shouldn't be able to create an extension loom when no looms exist.
          )
      ],
    );
  }
}
