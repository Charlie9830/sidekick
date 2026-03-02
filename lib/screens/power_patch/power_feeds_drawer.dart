import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

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
                    Text('${feedVm.feed.capacity}A',
                        style: Theme.of(context).typography.small)
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
