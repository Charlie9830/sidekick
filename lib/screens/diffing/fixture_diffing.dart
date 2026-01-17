import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/home/fixture_table/fixture_table_header.dart';
import 'package:sidekick/screens/home/fixture_table/fixture_table_row.dart';
import 'package:sidekick/view_models/fixture_diffing_item_view_model.dart';

class FixtureDiffing extends StatelessWidget {
  final List<FixtureDiffingItemViewModel> itemVms;
  const FixtureDiffing({
    super.key,
    required this.itemVms,
  });

  @override
  Widget build(BuildContext context) {
    const double dividerWidth = 8;
    const double hardWidth = 2220;
    const double tableWidth = (hardWidth / 2) - (dividerWidth / 2);
    const double dividerThickness = 12.0;

    return SingleChildScrollView(
      key: fixtureDiffingPageStorageKey,
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Headers
          const SizedBox(
            height: 64,
            child: Row(
              children: [
                SizedBox(width: tableWidth, child: FixtureTableHeader()),
                SizedBox(
                    width: dividerWidth,
                    child: VerticalDivider(
                      thickness: dividerThickness,
                    )),
                SizedBox(width: tableWidth, child: FixtureTableHeader()),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              width: hardWidth,
              child: ListView.builder(
                  itemCount: itemVms.length,
                  itemBuilder: (context, index) {
                    final vm = itemVms[index];

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: vm.original != null
                              ? DiffStateOverlay(
                                  diff: vm.overallDiff,
                                  child: FixtureTableRow(
                                    vm: vm.original!,
                                    deltas: vm.deltas,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(
                            width: dividerWidth,
                            height: 48,
                            child: VerticalDivider(
                              thickness: dividerThickness,
                            )),
                        Expanded(
                          child: vm.current != null
                              ? DiffStateOverlay(
                                  diff: vm.overallDiff,
                                  child: FixtureTableRow(
                                    vm: vm.current!,
                                    deltas: vm.deltas,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
