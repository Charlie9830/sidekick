import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/landing_pad.dart';
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
        LandingPad(
          icon: const Icon(Icons.add),
          title: 'Permanent',
          onAccept: (data) {
            if (data is OutletDragData) {
              onPermanentDrop(data.outletVms.toList());
            }
          },
          onWillAccept: (data) => true,
        ),
        LandingPad(
          icon: const Icon(Icons.add),
          title: 'Custom',
          onAccept: (data) {
            if (data is OutletDragData) {
              onCustomDrop(data.outletVms.toList());
            }
          },
          onWillAccept: (data) => true,
        ),
      ],
    );
  }
}
