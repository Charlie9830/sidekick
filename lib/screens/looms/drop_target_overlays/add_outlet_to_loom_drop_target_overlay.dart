import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/landing_pad.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class AddOutletToLoomDropTargetOverlay extends StatelessWidget {
  final void Function(List<OutletViewModel> droppedVms) onDrop;

  const AddOutletToLoomDropTargetOverlay({
    super.key,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LandingPad(
          icon: const Icon(Icons.add),
          title: 'Add',
          onAccept: (data) {
            print('Child Accepted');
            if (data is OutletDragData) {
              onDrop(data.outletVms.toList());
            }
          },
          onWillAccept: (data) => true,
        ),
      ],
    );
  }
}
