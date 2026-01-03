import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_rack.dart';
import 'package:sidekick/screens/racks/power_system_header.dart';
import 'package:sidekick/view_models/racks_view_model.dart';

class RacksScreen extends StatelessWidget {
  final RacksViewModel vm;
  const RacksScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: vm.powerItemVms.length,
      itemBuilder: (context, index) {
        final item = vm.powerItemVms[index];
        return switch (item) {
          PowerSystemItem i => PowerSystemHeader(key: Key(i.system.uid), vm: i),
          PowerRackItem i => PowerRack(key: Key(i.rack.uid), vm: i),
        };
      },
    );
  }
}
