import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms_v2/drag_data.dart';
import 'package:sidekick/screens/looms_v2/loom_drop_target.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class NewLoomDropTargetOverlay extends StatelessWidget {
  final void Function(List<OutletViewModel> droppedVms) onPermanentDrop;
  final void Function(List<OutletViewModel> droppedVms) onCustomDrop;
  const NewLoomDropTargetOverlay({
    super.key,
    required this.onCustomDrop,
    required this.onPermanentDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoomDropTarget(
            icon: const Icon(Icons.add),
            title: 'Permanent',
            onAccept: (data) {
              if (data is OutletDragData) {
                onPermanentDrop(data.outletVms.toList());
              }
            }),
        LoomDropTarget(
          icon: const Icon(Icons.add),
          title: 'Custom',
          onAccept: (data) {
            if (data is OutletDragData) {
              onCustomDrop(data.outletVms.toList());
            }
          },
        ),
      ],
    );
  }
}
