import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';

class LoomDiffing extends StatelessWidget {
  final List<LoomDiffingItemViewModel> itemVms;
  const LoomDiffing({
    required this.itemVms,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(height: 48),
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
                              child: LoomRowItem(
                                  deltas: item.deltas,
                                  loomVm: item.original!,
                                  reorderableListViewIndex: 0,
                                  children:
                                      item.original!.children.map((cableVm) {
                                    return buildCableRowItem(
                                        vm: cableVm,
                                        cableDelta:
                                            item.cableDeltas[cableVm.cable.uid],
                                        index: index,
                                        selectedCableIds: {},
                                        rowVms: [],
                                        parentLoomType:
                                            item.original!.loom.type.type,
                                        missingUpstreamCable:
                                            cableVm.missingUpstreamCable);
                                  }).toList()),
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 1,
                      child: item.current != null
                          ? DiffStateOverlay(
                              diff: item.overallDiff,
                              child: LoomRowItem(
                                  deltas: item.deltas,
                                  loomVm: item.current!,
                                  reorderableListViewIndex: 0,
                                  children:
                                      item.current!.children.map((cableVm) {
                                    return buildCableRowItem(
                                        vm: cableVm,
                                        cableDelta:
                                            item.cableDeltas[cableVm.cable.uid],
                                        index: index,
                                        selectedCableIds: {},
                                        rowVms: [],
                                        parentLoomType:
                                            item.current!.loom.type.type,
                                        missingUpstreamCable:
                                            cableVm.missingUpstreamCable);
                                  }).toList()),
                            )
                          : const SizedBox(),
                    ),
                  ],
                );
              }),
        ),
      ],
    );
  }
}
