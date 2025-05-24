import 'package:flutter/material.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/power_patch/location_row.dart';
import 'package:sidekick/screens/power_patch/multi_outlet_row.dart';
import 'package:sidekick/view_models/patch_diffing_item_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class PatchDiffing extends StatelessWidget {
  final List<PatchDiffingItemViewModel> itemVms;
  const PatchDiffing({
    required this.itemVms,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
              itemCount: itemVms.length,
              itemBuilder: (context, index) {
                final item = itemVms[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: item.original != null
                          ? DiffStateOverlay(
                              diff: item.overallDiff,
                              child: _buildRowSide(
                                  vm: item.original!,
                                  propertyDeltas: item.deltas,
                                  outletDeltas: item.outletDeltas))
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 1,
                      child: item.current != null
                          ? DiffStateOverlay(
                              diff: item.overallDiff,
                              child: _buildRowSide(
                                  vm: item.current!,
                                  propertyDeltas: item.deltas,
                                  outletDeltas: item.outletDeltas))
                          : const SizedBox(),
                    ),
                  ],
                );
              }),
        ),
      ],
    );
  }

  Widget _buildRowSide(
      {required PowerPatchRowViewModel vm,
      required PropertyDeltaSet propertyDeltas,
      required List<OutletDelta> outletDeltas}) {
    return switch (vm) {
      LocationRowViewModel vm => LocationRow(
          vm: vm,
          deltas: propertyDeltas,
        ),
      MultiOutletRowViewModel vm => MultiOutletRow(
          vm: vm, propertyDeltas: propertyDeltas, outletDeltas: outletDeltas),
      _ => throw UnimplementedError()
    };
  }
}
