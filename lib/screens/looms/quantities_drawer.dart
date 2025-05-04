import 'package:flutter/material.dart';
import 'package:sidekick/screens/looms/composition_item.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class QuantatiesDrawer extends StatelessWidget {
  final List<LoomStockQuantityViewModel> itemVms;
  final void Function() onSetupButtonPressed;
  const QuantatiesDrawer({
    super.key,
    required this.itemVms,
    required this.onSetupButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final columnHeaderStyle = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      width: 380,
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Text('Permanent Loom Usage',
                    style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                TextButton(
                    onPressed: onSetupButtonPressed,
                    child: const Text('Setup')),
              ],
            ),
            Row(
              children: [
                Text('Loom', style: columnHeaderStyle),

                const SizedBox(width: 200),

                Text(
                  'In Use',
                  style: columnHeaderStyle,
                ),

                const SizedBox(width: 20),
                Text(
                  "Available",
                  style: columnHeaderStyle,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                  itemCount: itemVms.length,
                  itemBuilder: (context, index) =>
                      CompositionItem(vm: itemVms[index])),
            )
          ],
        ),
      )),
    );
  }
}
