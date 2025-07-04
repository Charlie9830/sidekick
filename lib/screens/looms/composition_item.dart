import 'package:flutter/material.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class CompositionItem extends StatelessWidget {
  final LoomStockQuantityViewModel vm;
  const CompositionItem({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final available = vm.stock.qty - vm.inUse;
    return ListTile(
      enabled: vm.inUse > 0,
      title: Text(
        vm.stock.fullName,
      ),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.inUse > 0)
            Text(vm.inUse.toString(),
                style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(
            width: 60,
          ),
          Text(available.toString(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: available == 0
                      ? Colors.orangeAccent
                      : available < 0
                          ? Colors.redAccent
                          : Colors.green)),
        ],
      ),
    );
  }
}
