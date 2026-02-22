import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/power_rack.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerRacksAssignment extends StatelessWidget {
  final RacksScreenViewModel viewModel;

  const PowerRacksAssignment({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final racks = viewModel.powerRacks;

    final addRackButton =
        _PowerRackListTrailer(onAddButtonPressed: viewModel.onAddPowerRack);

    if (racks.isEmpty) {
      return addRackButton;
    }

    return ListView.builder(
      itemCount: racks.length,
      itemBuilder: (context, index) {
        final rackVm = racks[index];

        return PowerRack(
          viewModel: rackVm,
        );
      },
    );
  }
}

class _PowerRackListTrailer extends StatelessWidget {
  final void Function() onAddButtonPressed;

  const _PowerRackListTrailer({
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.secondary(
        onPressed: onAddButtonPressed,
        icon: const Icon(Icons.add),
        trailing: const Text('Add Power Rack'),
      ),
    );
  }
}
