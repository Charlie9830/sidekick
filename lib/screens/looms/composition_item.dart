import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/shad_list_item.dart';
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
    return ShadListItem(
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
                style: Theme.of(context).typography.normal),
          const SizedBox(
            width: 60,
          ),
          Text(available.toString(),
              style: Theme.of(context).typography.normal.copyWith(
                  color: available == 0
                      ? Colors.orange
                      : available < 0
                          ? Colors.red
                          : Colors.green)),
        ],
      ),
    );
  }
}
