import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class LoomDiffing extends StatelessWidget {
  final LoomDiffingViewModel vm;
  const LoomDiffing({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Toolbar(
            child: Row(
          children: [
            FileSelectButton(
              path: vm.comparisonFilePath,
              onFileSelectPressed: _handleSelectFileForComparePressed,
              hintText: 'Select file to compare with..',
              dropTargetName: 'Drop Phase Project here',
              onFileDropped: vm.onFileSelectedForCompare,
            ),
          ],
        )),
        Expanded(
          child: ListView.builder(
              itemCount: vm.itemVms.length,
              itemBuilder: (context, index) {
                final item = vm.itemVms[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: item.original != null
                            ? DiffStateOverlay(
                                diff: item.overallDiff,
                                child: LoomRowItem(
                                    loomVm: item.original!,
                                    reorderableListViewIndex: 0,
                                    children:
                                        item.original!.children.map((cableVm) {
                                      return buildCableRowItem(
                                          vm: cableVm,
                                          cableDelta: item
                                              .cableDeltas[cableVm.cable.uid],
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
                                    loomVm: item.current!,
                                    reorderableListViewIndex: 0,
                                    children:
                                        item.current!.children.map((cableVm) {
                                      return buildCableRowItem(
                                          vm: cableVm,
                                          cableDelta: item
                                              .cableDeltas[cableVm.cable.uid],
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
                  ),
                );
              }),
        ),
      ],
    );
  }

  void _handleSelectFileForComparePressed() async {
    final result = await openFile(
      confirmButtonText: 'Select',
      acceptedTypeGroups: kProjectFileTypes,
      initialDirectory: vm.initialDirectory,
    );

    if (result != null) {
      vm.onFileSelectedForCompare(result.path);
    }
  }
}
