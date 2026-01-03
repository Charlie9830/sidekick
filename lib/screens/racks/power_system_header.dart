import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/view_models/racks_view_model.dart';

class PowerSystemHeader extends StatelessWidget {
  final PowerSystemItem vm;
  const PowerSystemHeader({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const Icon(Icons.location_city, color: Colors.gray),
              const SizedBox(width: 12),
              Text(
                vm.system.name,
                style: Theme.of(context).typography.large,
              )
            ],
          )),
    );
  }
}
