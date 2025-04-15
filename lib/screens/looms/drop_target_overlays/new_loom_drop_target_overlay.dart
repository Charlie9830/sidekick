import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/modifier_key_listener.dart';
import 'package:sidekick/modifier_key_provider.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/drop_target_overlays/combine_into_sneak_info_tag.dart';
import 'package:sidekick/screens/looms/landing_pad.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class NewLoomDropTargetOverlay extends StatelessWidget {
  final void Function(List<OutletViewModel> droppedVms) onDropAsFeeder;
  final void Function(List<String> cableIds) onDropAsExtension;

  const NewLoomDropTargetOverlay(
      {super.key,
      required this.onDropAsFeeder,
      required this.onDropAsExtension});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LandingPad(
          icon: const Icon(Icons.add),
          title: 'Feeder',
          onAccept: (data) {
            if (data is OutletDragData) {
              onDropAsFeeder(data.outletVms.toList());
            }
          },
          onWillAccept: (data) => data is OutletDragData,
          infoTag: ModifierKeyMessenger.of(context)!
                  .keysDown
                  .contains(LogicalKeyboardKey.shiftLeft)
              ? const CombineIntoSneakInfoTag()
              : null,
        ),
        LandingPad(
          icon: const Icon(Icons.add),
          title: 'Extension',
          onAccept: (data) {
            if (data is CableDragData) {
              onDropAsExtension(data.cableIds.toList());
            }
          },
          onWillAccept: (data) => data is CableDragData,
        ),
      ],
    );
  }
}
