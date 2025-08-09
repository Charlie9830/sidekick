import 'package:flutter/material.dart';
import 'package:sidekick/diff_state_overlay.dart';
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: 2200,
              child: ListView.builder(
                  itemCount: itemVms.length,
                  itemBuilder: (context, index) {
                    final vm = itemVms[index];

                    return AbsorbPointer(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
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
                              width: dividerWidth, child: VerticalDivider()),
                          Expanded(
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
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
