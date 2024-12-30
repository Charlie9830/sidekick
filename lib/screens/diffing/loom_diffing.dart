import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/builders/build_cable_row_item.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/screens/diffing/change_overlay.dart';
import 'package:sidekick/screens/diffing/diff_item.dart';
import 'package:sidekick/screens/diffing/no_item_fallback.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/screens/looms/loom_row_item.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';

class LoomDiffing extends StatelessWidget {
  final LoomDiffingViewModel vm;
  const LoomDiffing({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: vm.itemVms.length,
        itemBuilder: (context, index) {
          final itemDiffVm = vm.itemVms[index];
          if (itemDiffVm.current is LocationDividerViewModel ||
              itemDiffVm.original is LocationDividerViewModel) {
            final dividerVm = (itemDiffVm.current ?? itemDiffVm.original)!
                as LocationDividerViewModel;
            return LocationHeaderRow(location: dividerVm.location);
          }

          if (itemDiffVm.current is LoomViewModel ||
              itemDiffVm.original is LoomViewModel) {
            final originalLoomVm = itemDiffVm.original as LoomViewModel?;
            final currentLoomVm = itemDiffVm.current as LoomViewModel?;

            return DiffItem(
                original: originalLoomVm == null
                    ? const NoItemFallback()
                    : ChangeOverlay(
                        changeType: itemDiffVm.current == null
                            ? ChangeType.deleted
                            : ChangeType.none,
                        child: LoomRowItem(
                          loomVm: originalLoomVm,
                          deltas: itemDiffVm.deltas,
                          onFocusDone: () {},
                          children: originalLoomVm.children
                              .mapIndexed(
                                (index, childVm) => buildCableRowItem(
                                    vm: childVm,
                                    index: index,
                                    selectedCableIds: {},
                                    rowVms: [],
                                    parentLoomType:
                                        originalLoomVm.loom.type.type,
                                    requestSelectionFocusCallback: () {}),
                              )
                              .toList(),
                        ),
                      ),
                current: currentLoomVm == null
                    ? const NoItemFallback()
                    : ChangeOverlay(
                        changeType: itemDiffVm.original == null
                            ? ChangeType.added
                            : ChangeType.none,
                        child: LoomRowItem(
                          loomVm: currentLoomVm,
                          deltas: itemDiffVm.deltas,
                          onFocusDone: () {},
                          children: currentLoomVm.children
                              .mapIndexed((index, childVm) => buildCableRowItem(
                                  vm: childVm,
                                  index: index,
                                  selectedCableIds: {},
                                  rowVms: [],
                                  parentLoomType: currentLoomVm.loom.type.type,
                                  requestSelectionFocusCallback: () {}))
                              .toList(),
                        ),
                      ));
          }

          return SizedBox.fromSize(size: Size.zero);
        });
  }
}
