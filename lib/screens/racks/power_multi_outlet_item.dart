import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/outlet_chip.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerMultiOutletItem extends StatelessWidget {
  final PowerMultiOutletViewModel vm;
  const PowerMultiOutletItem({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        color: vm.selected ? Theme.of(context).colorScheme.accent : null,
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            OutletChip(
                outletName: vm.multi.name,
                primaryLocationColor:
                    vm.parentLocation.color.firstColorOrNone.color)
          ],
        ));
  }
}
