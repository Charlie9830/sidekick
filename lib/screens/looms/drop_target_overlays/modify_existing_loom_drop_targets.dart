import 'package:flutter/material.dart';
import 'package:sidekick/custom_icons.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/landing_pad.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class ModifyExistingLoomDropTargets extends StatelessWidget {
  final void Function(Set<OutletViewModel> outletVms) onOutletsAdded;
  final void Function(Set<String> cableIds) onCablesMoved;
  final void Function(Set<String> cableIds) onCablesAdded;

  const ModifyExistingLoomDropTargets({
    super.key,
    required this.onOutletsAdded,
    required this.onCablesMoved,
    required this.onCablesAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor.withAlpha(128),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LandingPad(
            icon: const Icon(Icons.add),
            title: 'Add',
            onAccept: (data) {
              if (data is OutletDragData) {
                onOutletsAdded(data.outletVms);
              }

              if (data is CableDragData) {
                onCablesAdded(data.cableIds);
              }
            },
            onWillAccept: (data) =>
                data is OutletDragData || data is CableDragData,
          ),
          LandingPad(
            icon: const PlaceItemIcon(),
            title: 'Move',
            onAccept: (data) {
              onCablesMoved((data as CableDragData).cableIds);
            },
            onWillAccept: (data) => data is CableDragData,
          ),
        ],
      ),
    );
  }
}
