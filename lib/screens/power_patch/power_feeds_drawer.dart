import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/racks/power_rack.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerFeedsDrawer extends StatelessWidget {
  final PowerPatchViewModel vm;
  const PowerFeedsDrawer({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: vm.feedLoadings.length,
      itemBuilder: (context, index) {
        final feedVm = vm.feedLoadings[index];

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Card(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            filled: true,
            fillColor: Theme.of(context).colorScheme.sidebarAccent,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(feedVm.feed.name),
                    PowerMeter(
                        draw: CurrentDraw.fromPhaseLoad(feedVm.load),
                        capacity: feedVm.feed.capacity)
                  ],
                ),
                const SizedBox(height: 4.0),
                SizedBox(
                  height: 36,
                  child: BalanceGauge(
                      variance: Variance.small,
                      phaseALoad: feedVm.load.a,
                      phaseBLoad: feedVm.load.b,
                      phaseCLoad: feedVm.load.c),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
