import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class Sidebar extends StatelessWidget {
  final BreakoutCablingViewModel vm;

  const Sidebar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListView.builder(
      itemCount: vm.locationVms.length,
      itemBuilder: (context, index) {
        final item = vm.locationVms[index];
        return ShadListItem(
          selected: item.location.uid == vm.selectedLocationId,
          title: Text(item.location.name),
          onTap: () => item.onSelect(),
        );
      },
    ));
  }
}
