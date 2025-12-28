import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/screens/looms/composition_item.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

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
    final columnHeaderStyle = Theme.of(context).typography.small;
    return SizedBox(
      width: 420,
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Text('Permanent Loom Usage',
                    style: Theme.of(context).typography.large),
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
                  key: loomQuantitiesPageStorageKey,
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
