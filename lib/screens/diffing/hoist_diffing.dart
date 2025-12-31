import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/hoists/hoist_controller.dart';
import 'package:sidekick/view_models/hoist_controller_diffing_view_model.dart';

class HoistDiffing extends StatelessWidget {
  final List<HoistControllerDiffingViewModel> itemVms;
  const HoistDiffing({
    super.key,
    required this.itemVms,
  });

  @override
  Widget build(BuildContext context) {
    const double dividerWidth = 8;
    const double hardWidth = 2200;
    const double tableWidth = (hardWidth / 2) - (dividerWidth / 2);
    const double dividerThickness = 12.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: hardWidth,
              child: ListView.builder(
                  key: hoistDiffingPageStorageKey,
                  itemCount: itemVms.length,
                  itemBuilder: (context, index) {
                    final vm = itemVms[index];

                    return DragProxyController(
                      child: AbsorbPointer(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: tableWidth,
                              child: vm.original != null
                                  ? DiffStateOverlay(
                                      diff: vm.overallDiff,
                                      child: HoistController(
                                        viewModel: vm.original!,
                                        deltas: vm.deltas,
                                        channelDeltas: vm.channelDeltas,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                            const SizedBox(
                                width: dividerWidth,
                                height: 24,
                                child: VerticalDivider()),
                            SizedBox(
                              width: tableWidth,
                              child: vm.current != null
                                  ? DiffStateOverlay(
                                      diff: vm.overallDiff,
                                      child: HoistController(
                                        viewModel: vm.current!,
                                        deltas: vm.deltas,
                                        channelDeltas: vm.channelDeltas,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
