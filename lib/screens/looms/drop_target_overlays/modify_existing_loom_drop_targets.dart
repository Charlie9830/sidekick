import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/drag_data.dart';
import 'package:sidekick/screens/looms/landing_pad.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class ModifyExistingLoomDropTargets extends StatelessWidget {
  final void Function(Set<OutletViewModel> outletVms) onOutletsAdded;

  const ModifyExistingLoomDropTargets({
    super.key,
    required this.onOutletsAdded,
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
              assert(data is OutletDragData);
              onOutletsAdded((data as OutletDragData).outletVms);
            },
            onWillAccept: (data) => data is OutletDragData,
          ),
        ],
      ),
    );
  }
}
